mongoose = require "mongoose"
Q = require "q"
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
  expose: (io,modelName) ->
    d = Q.defer()
    model = mongoose.model modelName
    modelVersions = mongoose.model modelName+"Versions"
    io.of("/" + modelName).on "connection", (client) ->

      client.on "find", (data) ->
        collection = data.collection
        hash = data.hash
        find = if collection and collection.find then collection.find else {} 
        fields = if collection and collection.fields then collection.fields else null
        options = if collection and collection.options then collection.options else null
        model.find find, fields, options, (err,data) ->
          return if err
          client.emit("data." + hash, data)

      client.on "count", (data) ->
        collection = data.collection
        hash = data.hash
        find = if collection and collection.find then collection.find else {} 
        fields = if collection and collection.fields then collection.fields else null
        options = if collection and collection.options then collection.options else null
        model.find(find, fields, options).count (err,count) ->
          return if err
          client.emit("countdata." + hash, count)

      client.on "insert", (data) ->
        if data and data.hash
          if data.item
            obj = new model(data.item)
            obj.save (err) -> 
              return if err
              client.emit("insert.status." + data.hash, [true,obj])  
              client.broadcast.emit("inserted",obj)       
          else
            client.emit("insert.status." + data.hash,[false, uniqueName+" benötigt"])
      
      client.on "update", (data) ->
        if data and data.hash
          if data.item and data.item._id
            id = data.item._id
            ["_id","$$hashKey","__v"].forEach (string) -> delete data.item[string]
            oldversion = new modelVersions()
            oldversion.parentId = id
            oldversion.version = data.item.version
            oldversion.changes = data.changeItem
            oldversion.updated = data.item.updated
            oldversion.updatedBy = ""
            data.item.version++
            data.item.updated = Date.now()
            oldversion.save (err) ->
              if err
                client.emit("update.status." + data.hash, [false,"Error"])
                console.log(err)
              else
                model.update {_id:id}, data.item, {}, (err) -> 
                  if err
                    client.emit("update.status." + data.hash, [false,"Error"]) 
                  else                    
                    data.item._id = id
                    client.emit("update.status." + data.hash, [true, data.item]) 
                    client.broadcast.emit("updated",data.item)  
          else
            client.emit("update.status." + data.hash, [false,"_id fehlt"])

      client.on "remove", (data) ->
        if data and data.hash
          if data.itemid
            model.remove {_id:data.itemid}, (err) -> 
              if err
                client.emit("remove.status." + data.hash, [false,"Error"]) 
              else
                modelVersions.remove {parentId:data.itemid}, (err) ->
                  if err
                    client.emit("remove.status." + data.hash, [false,"Error"]) 
                  else
                    client.emit("remove.status." + data.hash, [true]) 
                    client.broadcast.emit("deleted",data.itemid) 
          else
            client.emit("remove.status." + data.hash, [false,"_id fehlt"])

      client.on "history", (data) ->
        collection = data.collection
        hash = data.hash
        find = if collection and collection.find then collection.find else {} 
        fields = if collection and collection.fields then collection.fields else null
        options = if collection and collection.options then collection.options else null
        modelVersions.find find, fields, options, (err,data) ->
          return if err
          client.emit("history." + hash, data)
    d.resolve()
    return d.promise
}
