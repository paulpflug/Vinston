nconf = require "nconf"
mongoose = require "mongoose"
Q = require "q"
nconf.file "./config.json"
connectionStringKey = "mongoConnection"

schema = {
  institutes:
    type: "objects"
    permissions:
      get:
        admin: []
        docent: []
        student: []
      set:
        admin: []
    initial: false
}

schema[connectionStringKey] = {
  type: "string"
  permissions:
    get:
      admin: []
    set:
      admin: []
  initial: true
  initialTest: (data) ->   
    options = { server: { auto_reconnect:false, socketOptions: { connectTimeoutMS: 500 }}}
    conn =  mongoose.createConnection data, options
    d = Q.defer() 
    conn.once "open", () -> 
      conn.db.collectionNames (err,coll) ->
        conn.db.dropDatabase() if not err and coll.length == 0
        conn.close () ->
          if err            
            d.reject(String(err))
          else
            console.log "db: "+conn.name+ " collections: "+coll.length
            d.resolve("db: "+conn.name+ " collections: "+coll.length)
    conn.on "error", (err) -> 
      d.reject(err)
    return d.promise
}

checkForInstalled = () ->
  console.log "searching for required config"
  resolve = () ->
    console.log "required config found"
    d.resolve(true)
  rejected = false
  reject = () ->
    console.log "required config not found"
    rejected = true
    d.resolve(false)
  d = Q.defer()
  tests = []
  for k,v of schema
    if v and v.initial
      if not nconf.get(k)
        reject()
      else if v.initialTest
        tests.push(v.initialTest(nconf.get(k)))
  if not rejected
    if tests.length > 0
      Q.all tests
      .done(resolve,reject)
    else
      resolve()
  return d.promise

getDBconnection = () ->
  d = Q.defer()
  connString = nconf.get(connectionStringKey)
  if connString
    conn = mongoose.createConnection(connString)
    conn.on "open", () ->
      d.resolve(conn)
  else
    d.reject("no connection string configured")
  return d.promise

module.exports = {
  nconf: nconf
  checkForInstalled: checkForInstalled
  schema: schema
  connectionStringKey: connectionStringKey
  getDBconnection: getDBconnection
}