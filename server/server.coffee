"use strict"

###
Module dependencies.
###
require 'coffee-script/register'
express = require "express"
http = require "http"
path = require "path"
mongoose = require "mongoose"
Q = require "q"
config = require "./models/configModel.coffee"
configInterface = require "./interfaces/configInterface.coffee"

users = require "./models/userModel.coffee"
authInterface = require "./interfaces/authInterface.coffee"

models = {
  rooms: "./models/roomModel.coffee"
  docents: "./models/docentModel.coffee"
  structures: "./models/structureModel.coffee"
  roomBookings: "./models/roomBookingModel.coffee"
  courses: "./models/courseModel.coffee"
  audiences: "./models/audienceModel.coffee"
}
dbInterface = require "./interfaces/dbInterface.coffee"


console.log("pid of serverchild on server side: " + process.pid)

app = express()
app.set "port", process.env.PORT or 9000
if process.env.dirname
  dir = process.env.dirname
else
  dir = path.join(__dirname,"..")
app.use(require("prerender-node"))
## setting dynamic routes
rootRoute = "/index.html"
app.route("/").get (req,res) -> res.sendfile(path.join(dir,"ngapp_compiled")+rootRoute)
## setting static routes
app.use express.static(path.join(dir, "resources"))
app.use express.static(path.join(dir, "ngapp_compiled"))
app.use "/vendor", express.static(path.join(dir, "vendor"))
## normal startup
startup = () -> 
  d = Q.defer()
  console.log "starting up"
  rootRoute = "/index.html"
  io = require("socket.io").listen(server)
  configInterface.expose(io, config)
  dbInterface.connectDB(config)
  .then () ->
    for name,model of models
      Model = require(model)
      for sem in config.get("semesters").content
        dbInterface.expose(io, Model,Model.name+"."+sem.name)
    authInterface.expose(io,users)
  .done () -> console.log "started up"; d.resolve()
  return d.promise
setup = (configInstalled) ->
  d = Q.defer()
  console.log "starting install"
  io = require("socket.io").listen(server)
  rootRoute = "/root/install/install.html"
  installInterface = require "./interfaces/installInterface.coffee"
  installInterface.exposeInstallInterface io,config, users,configInstalled
  .then () ->  
    console.log "finished install"
    io.of("/installUsers").emit("finished") 
    io.server.close()
    d.resolve()
  return d.promise
## starting server
server = app.listen app.get("port"), ->
  console.log "Express server listening on port %d in %s mode", app.get("port"), app.get("env")
  config.checkForInstalled()
  .then (success) ->
    d = Q.defer()
    if success        
      config.getDBconnection()
      .then users.checkForInstalled
      .then (success) ->
        if success             
          d.resolve()
        else
          d.reject(true)
    else
      d.reject(false)
    return d.promise
  .catch setup
  .then startup
server.on "close", () -> console.log "closing Express server"