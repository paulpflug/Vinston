_ = require "lodash"
Q = require "q"


module.exports = 
  expose : (io,config) ->
    io.of("/config").on "connection", (socket) ->
      # broadcaster of updates
      broadcastUpdate = (key) ->
        socket.broadcast.emit "update", key
      # listener for all items in the config schema
      _.forEach config.schema, (item, key)->
        # tester
        if item.test
          socket.on key + ".test", (request) ->            
            if (request and request.content and request.token)
              if socket.client.auth.inGroup("root")
                item.test(request.content).then(
                  ((info) -> socket.emit key + ".test." + request.token, {success:true, content:info}),
                  ((err) -> socket.emit key + ".test." + request.token, {success:false, content:err})
                  )
              else
                socket.emit key + ".test." + request.token, {success:false, content:"denied"}
        # getter
        socket.on key + ".get", (request) ->
          if (request and request.token)
            permission = socket.client.auth.getPermission(item.permissions.get)
            console.log permission
            response = config.getByPermission(key, permission)  
            socket.emit key + ".get." + request.token, response
        # getter for type
        socket.on key + ".type", (request) ->
          if (request and request.token)
            success = false
            content = false
            if socket.client.auth.getPermission(item.permissions.set)
              success = true
              content = item.type
            socket.emit key + ".type." + request.token, {success:success,content:content}
        # setter
        socket.on key + ".set", (request) ->
          set = () ->
            config.set(key, request.content)
            permission = socket.client.auth.getPermission(item.permissions.get)
            response = config.getByPermission(key, permission) 
            socket.emit key + ".set." + request.token, response
            broadcastUpdate(key)
          if (request and request.content and request.token)
            if socket.client.auth.getPermission(item.permissions.set)
              if item.test
                item.test request.content
                .then set, (err) -> 
                  socket.emit key + ".set." + request.token, {success:false, content:err}
              else
                set()
            else
              socket.emit key + ".set." + request.token, {success:false, content:"denied"}

    return Q()