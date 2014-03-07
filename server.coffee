"use strict"

###
Module dependencies.
###
require 'coffee-script/register'
express = require "express"
http = require "http"
path = require "path"
mongoose = require "mongoose"
config = require "./server/config.coffee"


mongoose.connect config.get('mongoConnection')

app = express()
dir = __dirname


# all environments
app.set "port", process.env.PORT or 9000
app.set "views", dir
app.set "view engine", "jade"
app.use express.logger("dev")
app.use express.json()
app.use express.urlencoded()
app.use express.methodOverride()
app.use app.router
app.use express.static(path.join(dir, "resources"))
app.use express.static(path.join(dir, "ngapp_compiled"))
app.use "/vendor", express.static(path.join(dir, "vendor"))

# development only
app.use express.errorHandler()  if "development" is app.get("env")

server = http.createServer(app)
server.listen app.get("port"), ->
  console.log "Express server listening on port %d in %s mode", app.get("port"), app.get("env")
io = require("socket.io").listen(server)

process.on "SIGTERM", () ->
  console.log "Closing"
  server.close()

server.on "close", ()->
  console.log "Closing db connection"
  mongoose.connection.close()

dbinterface = require "./components/dbinterface/dbinterface.coffee"
models = ["./server/admin/rooms/roomsModel.coffee"]
mongoose.connection.once "open", () ->
  for model in models
    do (model) -> 
      name = require(model)
      dbinterface.expose(io, name)


io.sockets.on "connection", (client) ->
  client.on "institutes", () ->
    client.emit("institutes.data", config.get("institutes"))