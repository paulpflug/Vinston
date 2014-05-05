_ = require "lodash"
Q = require "q"


module.exports = 
  expose : (io,config) ->
    d = Q.defer() 
    io.of("/config").on "connection", (client) ->
      _.forEach config.schema, (value,key)->
        if value.test
          client.on key + ".test", (data) ->            
            if (data and data.value and data.hash)
              if client.handshake.inGroup("root")
                value.test(data.value).then(
                  ((info) -> client.emit key + ".test." + data.hash, {success:true,info:info}),
                  ((err) -> client.emit key + ".test." + data.hash, {success:false,err:err})
                  )
              else
                client.emit key + ".test." + data.hash, false
        client.on key, () ->
          permission = client.handshake.getPermission(config.schema[key].permissions.get)
          response = config.getByPermission(key, permission)  
          client.emit key + ".data", response
        client.on key + ".set", (data) ->
          if (data and data.value and data.hash)
            permission = client.handshake.getPermission(config.schema[key].permissions.set)
            if config.setByPermission(key, data.value, permission)
              response = config.getByPermission(key, permission) 
            else
              response = false
            client.emit key + ".set." + data.hash, response
    d.resolve()
    return d.promise