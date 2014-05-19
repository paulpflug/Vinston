mongoose = require "mongoose"
Schema = mongoose.Schema
module.exports = exports = (schema, options) -> 
  read = "admin"
  write = "root"
  if options
    if options.read 
      read = options.read 
    if options.write
      write = options.write
    if options.modelName
      versionSchema = new Schema(
        parentId: String
        version: Number
        changes: { type: Array, default: [] }
        updated: type: Date
        updatedBy: { type: String, default: "" }
      )
      mongoose.model(options.modelName+"Versions", versionSchema)

  schema.add(
    updated: 
      type: Date
      default: Date.now 
      read: read
      write: write
    updatedBy: 
      type: String
      default: ""
      read: read
      write: write
    version: 
      type: String
      default: 1 
      read: read
      write: write
  )
  return {
    findRestriction:
      root:{}
      all:
        deleted: false
    history: read
  }