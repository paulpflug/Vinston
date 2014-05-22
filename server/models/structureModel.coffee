Schema = require("mongoose").Schema

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

module.exports = {
  name: "structures"
  schema: structureSchema
  remove: "root"
}