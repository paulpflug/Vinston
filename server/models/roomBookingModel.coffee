Schema = require("mongoose").Schema
deleted = require "./../mongoosePlugins/deleted.coffee"
versions = require "./../mongoosePlugins/versions.coffee"

roomBookingSchema = new Schema(
  course:
    type: Schema.Types.ObjectId
    read: "all"
    write: "admin"
  reason:
    type: String
    read: "all"
    write: "admin"
  user: 
    type: String
    read: "admin"
    write: "admin"
  duration: 
    type: Number
    read: "all"
    write: "admin"
  recurrence: 
    type: Number
    read: "all"
    write: "admin"
  day: 
    type: Date
    read: "all"
    write: "admin"
  time:
    start:
      type: Number
      read: "all"
      write: "admin"
    end: 
      type: Number
      read: "all"
      write: "admin"
  roomId: 
    type: Schema.Types.ObjectId
    read: "all"
    write: "admin"
  approved:
    type: Boolean
    read: "all"
    write: "admin"
)
roomBookingSchema.plugin(deleted)
module.exports = {
  name: "roomBookings"
  schema: roomBookingSchema
  findRestriction:
    root:{}
    admin:
      deleted: false
    all:
      deleted: false
      approved: true
  remove: "root"
}