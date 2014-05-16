_ = require "lodash"
Q = require "q"
mongoose = require "mongoose"

exposeInstallInterface = (io, config, users, configdone) ->
  d = Q.defer()
  exposeUserInterface = () ->
    console.log("exposing install user interface")
    io.of("/installUsers").on "connection", (client) ->
      client.on "root.set", (request) ->            
        if (request and request.content and request.token and request.content.name and request.content.password)
          request.content.group = "root"
          config.getDBconnection()
          .then (conn) ->
            user = users.loadModel(conn)
            root = new user(request.content)
            root.save (err) ->
              if err
                client.emit "root.set." + request.token, {success:false,content:err}
                return
              client.emit "root.set." + request.token, {success:true,content:false}
              d.resolve()
        else
          client.emit "root.set." + request.token, {success:false,content:false}                                    
    console.log("Install user interface exposed")

  console.log("exposing install config interface")

  io.of("/installConfig").on "connection", (client) ->
    if configdone
      exposeUserInterface()
    _.forEach config.schema, (item,key)->
      if item and item.initial
        broadcastUpdate = (key) ->
          client.broadcast.emit "update", key
        # tester
        if item.test
          client.on key + ".test", (request) ->
            if (request and request.content and request.token)
              item.test(request.content).then(
                ((info) -> client.emit key + ".test." + request.token, {success:true,content:info}),
                ((err) -> client.emit key + ".test." + request.token, {success:false,content:err})
                )
        # getter
        client.on key + ".get", (request) ->
          if (request and request.token)
            response = config.getByPermission(key, [])              
            client.emit key + ".get." + request.token, response
        
        # setter
        client.on key + ".set", (request) ->
          set = () ->
            config.set(key, request.content)
            response = config.getByPermission(key, []) 
            client.emit key + ".set." + request.token, response
            broadcastUpdate(key)
            config.checkForInstalled()
            .then (success) ->
              if success  
                config.getDBconnection()
                .then users.checkForInstalled
                .then (success) -> 
                  console.log "test"                   
                  if success
                    client.emit "done"
                    d.resolve() 
                  else                        
                    exposeUserInterface()
                    client.emit "configdone"
                .catch (err) -> console.log err
          if (request and request.content and request.token)            
            if item.test
              item.test(request.content)
              .then set, (err) -> 
                client.emit key + ".set." + request.token, {success:false, content:err}
            else
              set()

        
  console.log("Install config interface exposed")
  return d.promise


module.exports = {
  exposeInstallInterface: exposeInstallInterface
}
