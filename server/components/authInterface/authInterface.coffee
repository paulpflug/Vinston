Q = require "q"
mongoose = require "mongoose"
crypto = require "crypto"
groups = ["all","student","docent","admin","root"]  
tokenStore = {}
tokenExpiration = 1000*60*30 # 30 minutes
module.exports = 
  expose : (io,users) ->
    d = Q.defer() 
    userModel = users.loadModel()
    findUser = (userName) ->
      d = Q.defer()
      userModel.findOne {name:userName}, (err, user) ->
        if err
          d.reject(err)
        else
          d.resolve(user)
      return d.promise
    
    io.on "connection", (client) ->
      client.handshake.getPermission = (permissions) ->
        if client.handshake.user and client.handshake.user.group
          group = client.handshake.user.group
        else
          group = "all"
        permission = permissions[group]
        if not permission
          i = groups.indexOf(group)
          while i>=0
            i--
            permission = permissions[groups[i]]
            if permission
              break
        permission = false if not permission
        return permission
      client.handshake.inGroup = (group) ->
        if client.handshake.user and client.handshake.user.group
          userGroup = client.handshake.user.group
        else
          userGroup = "all"
        should = groups.indexOf(group)
        actual = groups.indexOf(userGroup)
        return (should <= actual)
      client.on "disconnect", () ->
        if client.handshake.token
          token = client.handshake.token
          if tokenStore[token]
            timoutObj = setTimeout (() -> delete tokenStore[token]), tokenExpiration
            if tokenStore[token].removeTimeout
              tokenStore[token].removeTimeout() 
            tokenStore[token].removeTimeout = () ->
              clearTimeout(timoutObj)
    io.of("/auth").on "connection", (client) ->
      client.on "auth.byToken", (item) ->
        response = false
        if item and item.token and item.hash
          token = item.token
          storedItem = tokenStore[token]
          if storedItem
            if storedItem.removeTimeout
              storedItem.removeTimeout()
            user = storedItem.user
            response = {name:user.name,group:user.group,token:token}
            client.handshake.user = user
            client.handshake.token = token
          client.emit "auth.byToken."+item.hash, response
      client.on "auth", (item) ->
        response = false
        if item and item.user and item.user.name and item.user.password and item.hash
          findUser(item.user.name)
          .then (user) ->
            user.comparePassword(item.user.password)
            .then (isMatch) ->
              if isMatch
                crypto.randomBytes 48, (ex, buf) ->
                  token = buf.toString "base64"
                  response = {name:user.name,group:user.group,token:token}
                  tokenStore[token] = {user:user}
                  timoutObj = setTimeout (() -> delete tokenStore[token]), tokenExpiration*10
                  if tokenStore[token].removeTimeout
                    tokenStore[token].removeTimeout() 
                  tokenStore[token].removeTimeout = () ->
                    clearTimeout(timoutObj)
                  client.handshake.user = user
                  client.handshake.token = token
                  client.emit "auth."+item.hash, response
              else
                client.emit "auth."+item.hash, response
          .catch () ->
            client.emit "auth."+item.hash, response
          
    d.resolve()
    return d.promise