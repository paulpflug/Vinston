mongoose = require "mongoose"
Schema = mongoose.Schema
modelName = "structure"
node = new Schema(
  name: 
    type: String
  nodes: [node]
)
structureSchema = new Schema(
  institute: 
    type: String
    default: ""
    read: "all"
    write: "admin"
  nodes: 
    type: [node]
    read: "all"
    write: "admin"
)

mongoose.model(modelName, structureSchema)
module.exports = {
  name: modelName
  remove: "root"
}