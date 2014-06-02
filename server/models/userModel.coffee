mongoose = require "mongoose"
Schema = mongoose.Schema
bcrypt = require "bcrypt"
SALT_WORK_FACTOR = 10
Q = require "q"
modelName = "users"
userSchema = new Schema(
  name: 
    type: String
    required: true
    index: 
      unique: true
    read: "root"
    write: "root" 
  password:
    type: String
    required: true
    write: "root"
  group: 
    type: String
    required: true
    read: "root"
    write: "root"
  lastLogin:
    type: Date
    read: "root"
)

userSchema.pre "save", (next) -> 
  user = this
  return next() unless user.isModified("password")
  bcrypt.genSalt SALT_WORK_FACTOR, (err, salt) -> 
    return next(err) if err
    bcrypt.hash user.password, salt, (err, hash) ->
      return next(err) if err
      user.password = hash
      return next()

userSchema.methods.comparePassword = (candidatePassword) ->
  d = Q.defer() 
  bcrypt.compare candidatePassword, this.password, (err, isMatch) -> 
    if err
      d.reject(err) 
    else
      d.resolve(isMatch)
  return d.promise

loadModel = (connection) ->
  obj = if connection then connection else mongoose 
  model = obj.model modelName, userSchema
  return model

checkForInstalled = (connection) ->
  d = Q.defer()
  console.log "searching for root"
  console.log "no connection given" if !connection
  if connection && connection.readyState
    model = loadModel(connection)
    model.find({group:"root"}).count (err,count) ->
      if err or not count or count == 0
        console.log "no root found"
        d.resolve(false)
      else
        console.log "root found"
        d.resolve(true)
      connection.close()
  else
    d.resolve(false)
  return d.promise

module.exports = {
  name: modelName
  checkForInstalled: checkForInstalled
  load: loadModel
}