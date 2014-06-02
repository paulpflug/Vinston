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
    userModel = users.load()
    findUser = (userName) ->
      d = Q.defer()
      userModel.findOne {name:userName}, (err, user) ->
        if err
          d.reject(err)
        else
          d.resolve(user)
      return d.promise
    setLoginDate = (userName) ->
      d = Q.defer()
      userModel.update {name: userName},{lastLogin: Date.now()},(err) ->
        if err
          d.reject(err)
        else
          d.resolve(userName)
      return d.promise
    io.use (socket,next) ->
      socket.client.auth = {
        getPermission: (permissions) ->
          return false if not permissions
          if socket.client.auth.user and socket.client.auth.user.group
            group = socket.client.auth.user.group
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
        inGroup: (group) ->
          return false if not group
          if socket.client.auth.user and socket.client.auth.user.group
            userGroup = socket.client.auth.user.group
          else
            userGroup = "all"
          should = groups.indexOf(group)
          actual = groups.indexOf(userGroup)
          return (should <= actual)
        }
      next()
    io.on "connection", (socket) ->
      socket.on "disconnect", () ->
        if socket.client.auth.token
          token = socket.client.auth.token
          if tokenStore[token]
            timoutObj = setTimeout (() -> delete tokenStore[token]), tokenExpiration
            if tokenStore[token].removeTimeout
              tokenStore[token].removeTimeout() 
            tokenStore[token].removeTimeout = () ->
              clearTimeout(timoutObj)
    io.of("/auth").on "connection", (socket) ->
      socket.on "auth.byToken", (request) ->
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
            setLoginDate user.name
            socket.client.auth.user = user
            socket.client.auth.token = token
          socket.emit "auth.byToken."+request.token, {success: success, content: content}
      socket.on "auth", (request) ->
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
                  setLoginDate user.name
                  socket.client.auth.user = user
                  socket.client.auth.token = token
                  socket.emit "auth."+request.token, {success: success, content: content}
              else
                socket.emit "auth."+request.token, {success: success, content: content}
          .catch () ->
            socket.emit "auth."+request.token, {success: success, content: content}
          
    d.resolve()
    return d.promise