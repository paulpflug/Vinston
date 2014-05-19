mongoose = require "mongoose"
deleted = require "./../mongoosePlugins/deleted.coffee"
versions = require "./../mongoosePlugins/versions.coffee"
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
)
roomSchema.plugin(deleted)
roomSchema.plugin(versions,{modelName:modelName})
mongoose.model(modelName, roomSchema)
module.exports = {
  name: modelName
  findRestriction:
    root:{}
    all:
      deleted: false
  history: "admin"
  remove: "root"
}