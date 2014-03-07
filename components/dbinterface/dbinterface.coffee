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
        model.find(find, fields, options).count (err,data) ->
          return if err
          client.emit(modelName + ".countdata", data)
          
      client.on modelName + ".save", (data) ->
        console.log "recieved"+data
        obj = new model(data)
        obj.save((err) -> return if err) 


}