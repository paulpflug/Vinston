_ = require "lodash"
Q = require "q"
mongoose = require "mongoose"

exposeInstallInterface = (io, config, users, configdone) ->
  d = Q.defer()
  exposeUserInterface = () ->
    console.log("exposing install user interface")
    io.of("/installUsers").on "connection", (client) ->
      client.on "admin.set", (data) ->            
        if (data and data.value and data.hash and data.value.name and data.value.password)
          data.value.group = "admin"
          config.getDBconnection()
          .then (conn) ->
            user = users.loadModel(conn)
            admin = new user(data.value)
            admin.save (err) ->
              if err
                console.log err
                client.emit "admin.set." + data.hash, false
                return
              client.emit "admin.set." + data.hash, true
              d.resolve()
        else
          client.emit "admin.set." + data.hash, false                                    
    console.log("Install user interface exposed")

  console.log("exposing install config interface")
  io.of("/installConfig").on "connection", (client) ->
    if configdone
      exposeUserInterface()
    _.forEach config.schema, (value,key)->
      if value and value.initial
        # getter
        client.on key, () ->
          client.emit key + ".data", config.nconf.get(key)
        # tester
        if value.initialTest
          client.on key + ".test", (data) ->
            if (data and data.value and data.hash)
              value.initialTest(data.value).then(
                ((info) -> client.emit key + ".test." + data.hash, {success:true,info:info}),
                ((err) -> client.emit key + ".test." + data.hash, {success:false,err:err})
                )
        # setter
        client.on key + ".set", (data) ->
          if (data and data.value and data.hash)
            save = () ->
              config.nconf.set(key,data.value)
              config.nconf.save()
              client.emit key + ".set." + data.hash, true
              config.checkForInstalled()
              .then (success) ->
                if success  
                  config.getDBconnection()
                  .then users.checkForInstalled
                  .then (success) ->                    
                    if success
                      client.emit "done"
                      d.resolve() 
                    else                        
                      exposeUserInterface()
                      client.emit "configdone"
            if value.initialTest
              value.initialTest(data.value).then(save,() -> client.emit key + ".set." + data.hash, false)
            else
              save()
        
  console.log("Install config interface exposed")
  return d.promise


module.exports = {
  exposeInstallInterface: exposeInstallInterface
}
