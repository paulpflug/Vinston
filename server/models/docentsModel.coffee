mongoose = require "mongoose"
Schema = mongoose.Schema
modelName = "docents"
docentSchema = new Schema(
  title:
    type: String
    read: "all"
    write: "admin"
  foreName:
    type: String
    read: "all"
    write: "admin"
  name:
    type: String
    read: "all"
    write: "admin"
  email:
    type: String
    read: "admin"
    write: "admin"    
  institute: 
    type: String
    default: ""
    read: "all"
    write: "admin"
  planned: 
    type: Date
    default: Date.now 
    read: "admin"
    write: "root"
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
docentVersionSchema = new Schema(
  parentId: String
  version: Number
  changes: { type: Array, default: [] }
  updated: type: Date
  updatedBy: { type: String, default: "" }
)

mongoose.model(modelName, docentSchema)
mongoose.model(modelName+"Versions", docentVersionSchema)
module.exports = {
  name: modelName
  findRestriction:
    root:{}
    all:
      deleted: false
  history: "admin"
  remove: "root"
}