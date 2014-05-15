mongoose = require "mongoose"
Q = require "q"
_ = require "lodash"

module.exports = {
  connectDB: (config) ->
    d = Q.defer()
    console.log "connecting mongoDB"
    mongoose.connect config.nconf.get(config.connectionStringKey)
    mongoose.connection.once "open", () -> 
      console.log "connected mongoDB"
      d.resolve()
    mongoose.connection.once "error", (err) -> 
      console.log "connection error: " + err
      d.reject()    
    return d.promise;
  disconnectDB: () ->
    d = Q.defer()
    console.log "disconnecting mongoDB" 
    mongoose.disconnect ()-> 
      console.log "disconnected mongoDB"
      d.resolve()
    return d.promise
  expose: (io,Model) ->
    allowedFields = {}
    model = mongoose.model Model.name

    modelVersions = mongoose.model Model.name+"Versions"
    io.of("/" + Model.name).on "connection", (client) ->
      getAllowedFields = (mode) ->
        mode = "read" if not mode
        if client.handshake.user and client.handshake.user.group
          group =  client.handshake.user.group
        else
          group = "all"
        if allowedFields[group] and allowedFields[group][mode]
          return allowedFields[group][mode]
        fields = []
        for k,v of model.schema.tree
          permission = client.handshake.inGroup v[mode]
          if permission
            fields.push(k)
        if not allowedFields[group]
          allowedFields[group] = {}
        allowedFields[group][mode] = fields
        return fields
      getReadFields = (fields) ->
        allowed = getAllowedFields()
        if fields and _.isString(fields)
          real = []
          asked = fields.split(" ")
          for s in asked
            if allowed.indexOf(s) > -1
              real.push(s)
          if real.length == 0
            real = allowed
        else
          real = allowed          
        return real.join(" ")
      getRealFinds = (finds) ->        
        additionalFinds = client.handshake.getPermission Model.findRestriction
        if finds and _.isPlainObject(finds)
          allowed = getAllowedFields()
          for k,v of finds
            if allowed.indexOf(k) == -1
              delete finds[k]
          for k,v of additionalFinds
            finds[k] = v
        else
          fins = additionalFinds
        return finds
      cleanQuery = (query) ->
        query = cleanQuerySimple(query)
        return {find: getRealFinds(query.find), fields: getReadFields(query.fields), options:query.options}
      cleanQuerySimple = (query) ->
        find = if query.find and _.isPlainObject(query.find) then query.find else {} 
        fields = if query.fields and _.isString(query.fields) then query.fields else null
        options = if query.options and _.isPlainObject(query.options) then query.options else null
        return {find: find, fields: fields, options:options}
      client.on "find", (request) ->
        if request and request.content and request.token
          query = cleanQuery(request.content)
          model.find query.find, query.fields, query.options, (err,data) ->
            success = false
            content = undefined
            if not err
              success = true
              content = data
            client.emit "find." + request.token, {success: success, content: content}

      client.on "count", (request) ->
        if request and request.content and request.token
          query = cleanQuery(request.content)
          model.find(query.find, null, query.options).count (err,count) ->
            success = false
            content = undefined
            if not err
              success = true
              content = count
            client.emit "count." + request.token, {success: success, content: content}

      client.on "insert", (request) ->
        if request and request.content and _.isPlainObject(request.content) and request.token
          success = false
          content = undefined
          fields = getAllowedFields("write")
          for k,v of request.content
            if fields.indexOf(k) == -1
              delete request.content[k]
          obj = new model(request.content)
          obj.save (err) -> 
            if not err
              success = true
              content = obj
              client.broadcast.emit "inserted", obj._id
            client.emit "insert." + request.token, {success: success, content: content}

      
      client.on "update", (request) ->
        if request and request.content and request.content._id  and _.isPlainObject(request.content) and request.token and request.changes
          success = false
          content = undefined
          item = request.content
          fields = getAllowedFields("write")
          for k,v of item
            if fields.indexOf(k) == -1
              delete item[k]
          id = item._id
          ["_id","$$hashKey","__v"].forEach (string) -> delete item[string]
          model.find {_id:id}, (err,oldItem) ->
            if not err
              oldversion = new modelVersions()
              oldversion.parentId = id
              oldversion.version = oldItem.version
              oldversion.changes = request.changes
              oldversion.updated = oldItem.updated
              oldversion.updatedBy = oldItem.updatedBy
              item.version++
              item.updated = Date.now()
              if client.handshake.user and client.handshake.user.name
                item.updatedBy = client.handshake.user.name
              oldversion.save (err) ->
                if not err
                  model.update {_id:id}, item, {}, (err) -> 
                    if not err
                      success = true
                      item._id = id
                      content = item
                      client.broadcast.emit("updated",id)  
                    client.emit "update." + request.token, {success: success, content: content}

      client.on "remove", (request) ->
        if request and request.content and request.token and request.content.id
          if client.handshake.inGroup(Model.remove)
            success = false
            content = undefined
            model.remove {_id:request.content.id}, (err) -> 
              if not err
                modelVersions.remove {parentId:request.content.id}, (err) ->
                  if not err
                    success = true
                    client.broadcast.emit "deleted", request.content.id
                  client.emit "remove." + request.token, {success: success, content: content}

                    

      client.on "history", (request) ->
        if request and request.content and request.token
          if client.handshake.inGroup(Model.history)
            query = cleanQuerySimple(request.content)
            modelVersions.find query.find, query.fields, query.options, (err,data) ->
              success = false
              content = undefined
              if not err
                success = true
                content = data
              client.emit "history." + request.token, {success: success, content: content}
    return Q()
}
