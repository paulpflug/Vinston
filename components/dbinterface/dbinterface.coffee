module.exports = {
  expose : (io,modelName) ->
    mongoose = require 'mongoose'

    model = mongoose.model modelName

    io.sockets.on "connection", (client) ->
      client.on "subscribe", (room) -> 
        client.join modelName if room == modelName 
      client.on "unsubscribe", (room) -> 
        client.leave modelName if room == modelName

      client.on modelName + ".find", (data) ->
        collection = data.collection
        hash = data.hash
        find = if collection and collection.find then collection.find else {} 
        fields = if collection and collection.fields then collection.fields else null
        options = if collection and collection.options then collection.options else null
        model.find find, fields, options, (err,data) ->
          return if err
          client.emit(modelName + ".data." + hash, data)

      client.on modelName + ".count", (data) ->
        collection = data.collection
        hash = data.hash
        find = if collection and collection.find then collection.find else {} 
        fields = if collection and collection.fields then collection.fields else null
        options = if collection and collection.options then collection.options else null
        model.find(find, fields, options).count (err,count) ->
          return if err
          client.emit(modelName + ".countdata." + hash, count)

      client.on modelName + ".insert", (data) ->
        if data and data.hash
          if data.item
            obj = new model(data.item)
            obj.save (err) -> 
              if err
                return
              else
                client.emit(modelName + ".insert.status." + data.hash, [true,obj])  
                client.broadcast.in(modelName).emit(modelName+".inserted",obj)       
          else
            client.emit(modelName + ".insert.status." + data.hash,[false, uniqueName+" benötigt"])
      
      client.on modelName + ".update", (data) ->
        if data and data.hash
          if data.item and data.item._id
            id = data.item._id
            ["_id","$$hashKey","__v"].forEach (string) -> delete data.item[string]
            model.update {_id:id}, data.item, {}, (err) -> 
              if err
                client.emit(modelName + ".update.status." + data.hash, [false,"Error"]) 
              else
                client.emit(modelName + ".update.status." + data.hash, [true]) 
                data.item._id = id
                client.broadcast.in(modelName).emit(modelName+".updated",data.item)  
          else
            client.emit(modelName + ".update.status." + data.hash, [false,"_id fehlt"])

      client.on modelName + ".remove", (data) ->
        if data and data.hash
          if data.itemid
            model.remove {_id:data.itemid}, (err) -> 
              if err
                client.emit(modelName + ".remove.status." + data.hash, [false,"Error"]) 
              else
                client.emit(modelName + ".remove.status." + data.hash, [true]) 
                client.broadcast.in(modelName).emit(modelName+".deleted",data.itemid) 
          else
            client.emit(modelName + ".remove.status." + data.hash, [false,"_id fehlt"])
}