module.exports = {
  expose : (io,modelName) ->
    mongoose = require 'mongoose'

    model = mongoose.model modelName

    io.sockets.on "connection", (client) ->
      client.on modelName + ".find", (collection) ->
        find = if collection and collection.find then collection.find else {} 
        fields = if collection and collection.fields then collection.fields else null
        options = if collection and collection.options then collection.options else null
        model.find find, fields, options, (err,data) ->
          return if err
          client.emit(modelName + ".data", data)

      client.on modelName + ".count", (collection) ->
        find = if collection and collection.find then collection.find else {} 
        fields = if collection and collection.fields then collection.fields else null
        options = if collection and collection.options then collection.options else null
        model.find(find, fields, options).count (err,count) ->
          return if err
          client.emit(modelName + ".countdata", count)

      client.on modelName + ".insert", (data) ->
        if data 
          obj = new model(data)
          obj.save (err) -> 
            if err
              return
            else
              client.emit(modelName + ".insert.status", [true,"Ok",obj])         
        else
          client.emit(modelName + ".insert.status",[false, uniqueName+" benötigt"])
      
      client.on modelName + ".update", (data) ->
        if data and data._id
          id = data._id
          ["_id","$$hashKey","__v"].forEach (string) -> delete data[string]
          model.update {_id:id}, data, {}, (err) -> 
            if err
              client.emit(modelName + ".update.status", [false,"Error"]) 
            else
              client.emit(modelName + ".update.status", [true,"Ok"]) 
        else
          client.emit(modelName + ".update.status", [false,"_id fehlt"])

      client.on modelName + ".remove", (dataid) ->
        if dataid
          model.remove {_id:dataid}, (err) -> 
            if err
              client.emit(modelName + ".remove.status", [false,"Error"]) 
            else
              client.emit(modelName + ".remove.status", [true,"Ok"]) 
        else
          client.emit(modelName + ".remove.status", [false,"_id fehlt"])
}