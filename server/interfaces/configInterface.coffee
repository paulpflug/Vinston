_ = require "lodash"
Q = require "q"


module.exports = 
  expose : (io,config) ->
    io.of("/config").on "connection", (client) ->
      # broadcaster of updates
      broadcastUpdate = (key) ->
        client.broadcast.emit "update", key
      # listener for all items in the config schema
      _.forEach config.schema, (item, key)->
        # tester
        if item.test
          client.on key + ".test", (request) ->            
            if (request and request.content and request.token)
              if client.handshake.inGroup("root")
                item.test(request.content).then(
                  ((info) -> client.emit key + ".test." + request.token, {success:true, content:info}),
                  ((err) -> client.emit key + ".test." + request.token, {success:false, content:err})
                  )
              else
                client.emit key + ".test." + request.token, {success:false, content:"denied"}
        # getter
        client.on key + ".get", (request) ->
          if (request and request.token)
            permission = client.handshake.getPermission(item.permissions.get)
            console.log permission
            response = config.getByPermission(key, permission)  
            client.emit key + ".get." + request.token, response
        # getter for type
        client.on key + ".type", (request) ->
          if (request and request.token)
            success = false
            content = false
            if client.handshake.getPermission(item.permissions.set)
              success = true
              content = item.type
            client.emit key + ".type." + request.token, {success:success,content:content}
        # setter
        client.on key + ".set", (request) ->
          set = () ->
            config.set(key, request.content)
            permission = client.handshake.getPermission(item.permissions.get)
            response = config.getByPermission(key, permission) 
            client.emit key + ".set." + request.token, response
            broadcastUpdate(key)
          if (request and request.content and request.token)
            if client.handshake.getPermission(item.permissions.set)
              if item.test
                item.test request.content
                .then set, (err) -> 
                  client.emit key + ".set." + request.token, {success:false, content:err}
              else
                set()
            else
              client.emit key + ".set." + request.token, {success:false, content:"denied"}

    return Q()