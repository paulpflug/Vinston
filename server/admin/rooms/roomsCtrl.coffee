require 'coffee-script/register'
require './roomsModel.coffee'
mongoose = require 'mongoose' 
Room = mongoose.model 'Room' 

exports.read = (sender) ->
  Room.find {}, (err, rooms) ->
    sender(rooms)


exports.create = (data) -> 
  room = new Room(data)
  room.save()
