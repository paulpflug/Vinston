mongoose = require "mongoose"
Schema = mongoose.Schema
modelName = "rooms"
roomSchema = new Schema(
  name:
    type: String
    read: "all"
    write: "admin"
  advancedName:
    type: String
    read: "all"
    write: "admin"
  hisID:
    type: String
    read: "all"
    write: "admin"
  capacity:
    type: Number
    min: 1
  institute: 
    type: String
    default: ""
    read: "all"
    write: "admin"
  secInstitutes: 
    type: Array
    default: []
    read: "docent"
    write: "admin"
  conditionalInstitutes: 
    type: Array
    default: []
    read: "docent"
    write: "admin"
  deleted: 
    type: Boolean
    default: false
    read: "admin"
    write: "admin"
  updated: 
    type: Date
    default: Date.now 
    read: "admin"
    write: "root"
  updatedBy: 
    type: String
    default: ""
    read: "admin"
    write: "root"
  version: 
    type: String
    default: 1 
    read: "admin"
    write: "root"
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
module.exports = {
  name: modelName
  findRestriction:
    root:{}
    all:
      deleted: false
  history: "admin"
  remove: "root"
}