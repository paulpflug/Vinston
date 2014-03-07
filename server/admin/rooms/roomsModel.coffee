mongoose = require('mongoose')
Schema = mongoose.Schema
modelName = "rooms"
roomSchema = new Schema(
  name: String,
  institute: String,
  secInstitutes: Array
)

mongoose.model(modelName, roomSchema)
module.exports = modelName