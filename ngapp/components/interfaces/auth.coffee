angular.module('interfaces')
.service "auth", ($rootScope,$q,$modal,generate,session) ->
  socket = io.connect("/auth")
  authenticated = false
  groups = ["all","student","docent","admin","root"] 
  this.tokenLogin = () ->
    d = $q.defer()
    user = session.getUser()
    if not authenticated
      if user and user.token
        token = generate.token()
        item = {content: user.token, token: token}
        socket.emit "auth.byToken", item
        socket.once "auth.byToken."+token, (response) ->
          if response.success and response.content and response.content.name and response.content.group
            user = {name:response.content.name,group:response.content.group,token:user.token}
            authenticated = true
            session.setUser(user)
            d.resolve(user)
          else
            delete user.token
            session.setUser(user)
            d.reject()
      else
        d.reject()
    else
      d.resolve(user)
    return d.promise
  this.setUser = (newUser) ->
    reject = () ->
      authenticated = false
      session.setUser(false)
      d.reject()
    d = $q.defer()
    if newUser
      token = generate.token()
      item = {content: newUser, token: token}  
      socket.emit "auth", item
      socket.once "auth."+token, (response) ->
        if response.success and response.content and response.content.name and response.content.group and response.content.token
          user = {name:response.content.name,group:response.content.group,token:response.content.token}
          authenticated = true
          session.setUser(user)
          d.resolve(user)
        else
          reject()
    else
      reject()
    return d.promise

  showLoginModal = (staticModal) ->
    d = $q.defer()
    staticModal = false if not staticModal
    backdrop = if staticModal then "static" else true
    modalInstance = $modal.open {
        keyboard: staticModal
        backdrop: backdrop
        templateUrl: "indexLogin.html"
        controller: "loginCtrl"
        resolve: {
          userName: () -> return session.getUser().name
        }
      }
    modalInstance.result.then ((user)->d.resolve(user)),(err)->d.reject(err)
    return d.promise

  this.showLoginModal = showLoginModal

  this.requirePermission = (group,staticModal) ->
    d = $q.defer()
    if group == "all"
      d.resolve(true)
    else
      user = session.getUser()
      if (user and user.group and authenticated)
        d.resolve(inGroup(group,user))
      else
        this.tokenLogin()
        .then ((user) -> d.resolve(inGroup(group,user))), (() ->
          showLoginModal(staticModal)
          .then ((user)->d.resolve(inGroup(group,user))), ()->d.resolve(false))
    return d.promise

  inGroup = (group,user) ->
    if not user
      user = session.getUser()
    if user and user.group
      userGroup = user.group
    else
      userGroup = "all"
    should = groups.indexOf(group)
    actual = groups.indexOf(userGroup)
    return (should <= actual)

  this.inGroup = inGroup

  return this