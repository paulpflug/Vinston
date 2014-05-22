Schema = require("mongoose").Schema
deleted = require "./../mongoosePlugins/deleted.coffee"
versions = require "./../mongoosePlugins/versions.coffee"

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
    read: "all"
    write: "admin"
  institute: 
    type: String
    default: ""
    read: "all"
    write: "admin"
  secInstitutes: 
    type: [String]
    default: []
    read: "docent"
    write: "admin"
  conditionalInstitutes: 
    type: [String]
    default: []
    read: "docent"
    write: "admin"
  bookable:
    type: String
    read: "student"
    write: "admin"

)
roomSchema.plugin(deleted)
roomSchema.plugin(versions)
module.exports = {
  name: "rooms"
  schema: roomSchema
  findRestriction:
    root:{}
    all:
      deleted: false
  history: "admin"
  remove: "root"
}