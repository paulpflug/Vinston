module.exports = exports = (schema, options) -> 
  read = "admin"
  write = "admin"
  if options
    if options.read 
      read = options.read 
    if options.write
      write = options.write
  schema.add(
    deleted: 
      type: Boolean
      default: false
      read: read
      write: write
  )
 