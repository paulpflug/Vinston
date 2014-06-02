Schema = require("mongoose").Schema
deleted = require "./../mongoosePlugins/deleted.coffee"
versions = require "./../mongoosePlugins/versions.coffee"
audienceSchema = new Schema(
  abbr:
    type: String
    read: "all"
    write: "admin"
  name:
    type: String
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
    read: "all"
    write: "admin"
  terms:
    type: [String]
    default: []
    read: "all"
    write: "admin"
  differentiations:
    type: [String]
    default: []
    read: "all"
    write: "admin"
)
audienceSchema.plugin(deleted)
audienceSchema.plugin(versions)
module.exports = {
  name: "audiences"
  schema: audienceSchema
  findRestriction:
    root:{}
    all:
      deleted: false
  history: "admin"
  remove: "root"
}