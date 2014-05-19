mongoose = require "mongoose"
deleted = require "./../mongoosePlugins/deleted.coffee"
versions = require "./../mongoosePlugins/versions.coffee"
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
)

docentSchema.plugin(deleted)
docentSchema.plugin(versions,{modelName:modelName})
mongoose.model(modelName, docentSchema)
module.exports = {
  name: modelName
  findRestriction:
    root:{}
    all:
      deleted: false
  history: "admin"
  remove: "root"
}