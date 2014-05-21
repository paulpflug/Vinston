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