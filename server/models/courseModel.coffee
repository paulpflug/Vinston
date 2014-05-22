Schema = require("mongoose").Schema
deleted = require "./../mongoosePlugins/deleted.coffee"
versions = require "./../mongoosePlugins/versions.coffee"
literatureSchema = new Schema(
  name: String
  author: String
  publisher: String
)
teacherSchema = new Schema(
  typedName: String
  id: Schema.Types.ObjectId
)
audienceSchema = new Schema(
  id: Schema.Types.ObjectId
  name: String
  terms: [String]
  facultative: Boolean
)
plannedBlockSchema = new Schema(
  roomId: Schema.Types.ObjectId
  day: String
  time:
    start: Number
    end: Number
)
blockSchema = new Schema(
  day: String
  time:
    start: Number
    end: Number
)
groupSchema = new Schema(
  teachers: [teacherSchema]
  author: String
  publisher: String
  plannedBlocks: [plannedBlockSchema]
  specifiedAudience: [audienceSchema]
  wishes:
    blocks: [blockSchema]
    roomIds: [Schema.Types.ObjectId]
    roomCapacity: Number
)
lessonSchema = new Schema(
  Type: String
  duration: Number
  recurrence: Number
  facultative: Boolean
  groups: [groupSchema]
)
courseSchema = new Schema(
  abbreviation:
    type: String
    read: "all"
    write: "docent"
  name:
    type: String
    read: "all"
    write: "docent"
  structureTies:
    type: [String]
    read: "all"
    write: "docent"
  responsibleUser:
    type: String
    read: "docent"
    write: "docent"
  creditPoints:
    type: Number
    read: "all"
    write: "docent"
  duration:
    type: Number
    read: "all"
    write: "docent"
  recurrence:
    type: [Number]
    read: "docent"
    write: "docent"
  period:
    name:
      type: String
      read: "all"
      write: "docent"
    start:
      type: Date
      read: "all"
      write: "docent"
    end:
      type: Date
      read: "all"
      write: "docent"
  audiences:
    type: [audienceSchema]
    read: "all"
    write: "docent"
  literature:
    type: [literatureSchema]
    read: "all"
    write: "docent"
  lessons:
    type: [lessonSchema]
    read: "all"
    write: "docent"
  sequence:
    type: [String]
    read: "docent"
    write: "docent"
)
courseSchema.plugin(deleted)
courseSchema.plugin(versions)
module.exports = {
  name: "courses"
  schema: courseSchema
  findRestriction:
    root:{}
    all:
      deleted: false
  history: "docent"
  remove: "root"
}