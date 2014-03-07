mongoose = require('mongoose')
Schema = mongoose.Schema

RoomSchema = new Schema(
  name: String,
  institute: String,
  secInstitutes: Array
)

mongoose.model('Room', RoomSchema)