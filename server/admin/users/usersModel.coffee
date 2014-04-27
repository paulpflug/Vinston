mongoose = require "mongoose"
Schema = mongoose.Schema
bcrypt = require "bcrypt"
SALT_WORK_FACTOR = 10
Q = require "q"
modelName = "users"
userSchema = new Schema(
  name: { type: String, required: true, index: { unique: true } }
  password: { type: String, required: true }
  group: { type: String, required: true }
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

userSchema.methods.comparePassword = (candidatePassword, cb) -> 
  bcrypt.compare candidatePassword, this.password, (err, isMatch) -> 
    return cb(err) if err 
    cb null, isMatch

loadModel = (connection) ->
  obj = if connection then connection else mongoose 
  model = obj.model modelName, userSchema
  return model

checkForInstalled = (connection) ->
  d = Q.defer()
  console.log "searching for admin"
  console.log "no connection given" if !connection
  if connection && connection.readyState
    model = loadModel(connection)
    model.find({group:"admin"}).count (err,count) ->
      if err or not count or count == 0
        console.log "no admin found"
        d.resolve(false)
      else
        console.log "admin found"
        d.resolve(true)
      connection.close()
  else
    d.resolve(false)
  return d.promise

module.exports = {
  modelName: modelName
  checkForInstalled: checkForInstalled
  loadModel: loadModel
}