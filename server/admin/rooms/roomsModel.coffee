mongoose = require('mongoose')
Schema = mongoose.Schema
modelName = "rooms"
roomSchema = new Schema(
  name: String
  institute: { type: String, default: "" }
  secInstitutes: { type: Array, default: [] }
  deleted: { type: Boolean, default: false }
  updated: { type: Date, default: Date.now }
  updatedBy: { type: String, default: "" }
  version: { type: String, default: 1 }
)
roomVersionSchema = new Schema(
  parentId: String
  version: Number
  changes: { type: Array, default: [] }
  updated: type: Date
  updatedBy: { type: String, default: "" }
)

mongoose.model(modelName, roomSchema)
mongoose.model(modelName+"Versions", roomVersionSchema)
module.exports = modelName