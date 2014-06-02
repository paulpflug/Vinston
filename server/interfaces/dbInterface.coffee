mongoose = require "mongoose"
Schema = mongoose.Schema
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
  expose: (io,Model,name) ->
    allowedFields = {}
    if not name
      name = Model.name
    if Model.load
      model = Model.load()
    else
      model = mongoose.model name, Model.schema
    if Model.history
      versionSchema = new Schema(
        parentId: String
        version: Number
        changes: { type: Array, default: [] }
        updated: type: Date
        updatedBy: { type: String, default: "" }
      )
      modelVersions = mongoose.model(name+"Versions", versionSchema)
    console.log "exposing "+name
    io.of("/" + name).on "connection", (socket) ->
      socket.emit "isReal"
      getAllowedFields = (mode) ->
        mode = "read" if not mode
        if socket.client.auth.user and socket.client.auth.user.group
          group =  socket.client.auth.user.group
        else
          group = "all"
        if allowedFields[group] and allowedFields[group][mode]
          return allowedFields[group][mode]
        fields = []
        for k,v of model.schema.tree
          permission = socket.client.auth.inGroup v[mode]
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
        if Model.findRestriction
          additionalFinds = socket.client.auth.getPermission Model.findRestriction
        if finds and _.isPlainObject(finds)
          allowed = getAllowedFields()
          for k,v of finds
            if allowed.indexOf(k) == -1
              delete finds[k]
          if additionalFinds
            for k,v of additionalFinds
              finds[k] = v
        else
          if additionalFinds
            finds = additionalFinds
          else
            finds = {}
        return finds
      cleanQuery = (query) ->
        query = cleanQuerySimple(query)
        return {find: getRealFinds(query.find), fields: getReadFields(query.fields), options:query.options}
      cleanQuerySimple = (query) ->
        find = if query.find and _.isPlainObject(query.find) then query.find else {} 
        fields = if query.fields and _.isString(query.fields) then query.fields else null
        options = if query.options and _.isPlainObject(query.options) then query.options else null
        return {find: find, fields: fields, options:options}
      
      socket.on "find", (request) ->
        if request and request.content and request.token
          query = cleanQuery(request.content)
          model.find query.find, query.fields, query.options, (err,data) ->
            success = false
            content = undefined
            if not err
              success = true
              content = data
            socket.emit "find." + request.token, {success: success, content: content}

      socket.on "count", (request) ->
        if request and request.content and request.token
          query = cleanQuery(request.content)
          model.find(query.find, null, query.options).count (err,count) ->
            success = false
            content = undefined
            console.log err
            if not err
              success = true
              content = count
            socket.emit "count." + request.token, {success: success, content: content}

      socket.on "insert", (request) ->
        console.log request
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
              socket.broadcast.emit "inserted", obj._id
            socket.emit "insert." + request.token, {success: success, content: content}

      
      socket.on "update", (request) ->
        if request and request.content and request.content._id  and _.isPlainObject(request.content) and request.token and request.changes
          success = false
          content = undefined
          item = request.content
          id = item._id
          fields = getAllowedFields("write")
          for k,v of item
            if fields.indexOf(k) == -1
              delete item[k]
          ["_id","$$hashKey","__v"].forEach (string) -> delete item[string]
          if Model.history
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
                if socket.client.auth.user and socket.client.auth.user.name
                  item.updatedBy = socket.client.auth.user.name
                oldversion.save (err) ->
                  if not err
                    model.update {_id:id}, item, (err) -> 
                      if not err
                        success = true
                        item._id = id
                        content = item
                        socket.broadcast.emit("updated",id)  
                      socket.emit "update." + request.token, {success: success, content: content}
          else
            model.update {_id:id}, item, (err) -> 
              if not err
                success = true
                item._id = id
                content = item
                socket.broadcast.emit("updated",id)  
              socket.emit "update." + request.token, {success: success, content: content}
      if Model.remove
        socket.on "remove", (request) ->
          if request and request.content and request.token and request.content.id
            if socket.client.auth.inGroup(Model.remove)
              success = false
              content = undefined
              model.remove {_id:request.content.id}, (err) -> 
                if not err
                  if Model.history
                    modelVersions.remove {parentId:request.content.id}, (err) ->
                      if not err
                        success = true
                        socket.broadcast.emit "deleted", request.content.id
                      socket.emit "remove." + request.token, {success: success, content: content}
                  else
                    success = true
                    socket.broadcast.emit "deleted", request.content.id
                if not Model.History
                  socket.emit "remove." + request.token, {success: success, content: content}

                    
      if Model.history
        socket.on "history", (request) ->
          if request and request.content and request.token
            if socket.client.auth.inGroup(Model.history)
              query = cleanQuerySimple(request.content)
              modelVersions.find query.find, query.fields, query.options, (err,data) ->
                success = false
                content = undefined
                if not err
                  success = true
                  content = data
                socket.emit "history." + request.token, {success: success, content: content}
    return Q()
}
