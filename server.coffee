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


mongoose.connection.once "open", () ->
  rooms = require "./server/admin/rooms/roomsCtrl.coffee"

  io.sockets.on "connection", (client) ->
    client.on "rooms.read", () ->
      rooms.read (data) ->
        client.emit "roomsData",data
    client.on "rooms.create", (data) ->
      console.log "recieved"+data
      rooms.create(data) 