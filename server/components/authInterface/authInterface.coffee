Q = require "q"
mongoose = require "mongoose"
crypto = require "crypto"
util = require "util"

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
        if util.isArray(permissions)
          i = groups.indexOf(group)
          while i < groups.length
            j = permissions.indexOf(groups[i])
            i++
            if j > -1
              permission = true
              break
        else
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
      client.on "auth.byToken", (request) ->
        success = false
        content = false
        if request and request.token and request.content
          token = request.content
          storedItem = tokenStore[token]
          if storedItem
            if storedItem.removeTimeout
              storedItem.removeTimeout()
            storedItem.resetLongTimeout()
            user = storedItem.user
            content = {name:user.name,group:user.group}
            success = true
            client.handshake.user = user
            client.handshake.token = token
          client.emit "auth.byToken."+request.token, {success: success, content: content}
      client.on "auth", (request) ->
        success = false
        content = false
        if request and request.content and request.content.name and request.content.password and request.token
          findUser(request.content.name)
          .then (user) ->
            user.comparePassword(request.content.password)
            .then (isMatch) ->
              if isMatch
                crypto.randomBytes 48, (ex, buf) ->
                  token = buf.toString "base64"
                  success = true
                  content = {name:user.name,group:user.group,token:token}
                  tokenStore[token] = {user:user}
                  tokenStore[token].resetLongTimeout = () ->
                    if timoutObj
                      clearTimeout(timoutObj)
                    timoutObj = setTimeout (() -> delete tokenStore[token]), tokenExpiration*50
                  tokenStore[token].resetLongTimeout()
                  client.handshake.user = user
                  client.handshake.token = token
                  client.emit "auth."+request.token, {success: success, content: content}
              else
                client.emit "auth."+request.token, {success: success, content: content}
          .catch () ->
            client.emit "auth."+request.token, {success: success, content: content}
          
    d.resolve()
    return d.promise