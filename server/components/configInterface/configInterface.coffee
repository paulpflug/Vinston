_ = require "lodash"
Q = require "q"
module.exports = 
  expose : (io,config) ->
    d = Q.defer() 
    io.of("/config").on "connection", (client) ->
      _.forEach config.schema, (value,key)->
        client.on key, () ->
          client.emit key + ".data", config.nconf.get(key)
        client.on key + ".set", (data) ->
          if (data and data.value and data.hash)
            config.nconf.set(key,data.value)
            config.nconf.save()
            client.emit key + ".set." + data.hash, config.nconf.get(key)
      d.resolve()
    return d.promise