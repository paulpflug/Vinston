mongoose = require('mongoose')
Schema = mongoose.Schema
modelName = "rooms"
roomSchema = new Schema(
  name: String,
  institute: { type: String, default: "" },
  secInstitutes: { type: Array, default: [] }
)

mongoose.model(modelName, roomSchema)
module.exports = modelName