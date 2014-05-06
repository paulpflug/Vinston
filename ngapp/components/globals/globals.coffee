mod = angular.module('globals', ["ngCookies"])

mod.service "config", ($rootScope,$q) ->
  socket = io.connect("/config")
  config = {}
  this.get = (name) ->
    d = $q.defer()
    if config[name] and config[name].length > 0
      d.resolve(config[name])
      $rootScope.$$phase || $rootScope.$apply() 
    else  
      socket.once name + ".data", (data) ->
        d.resolve(data)
        config[name] = data
        $rootScope.$$phase || $rootScope.$apply() 
        return
      socket.emit name      
    return d.promise
  return this

mod.service "auth", ($rootScope,$q,$modal,md5,session) ->
  socket = io.connect("/auth")
  user = false
  groups = ["all","student","docent","admin","root"] 
  this.tokenLogin = () ->
    d = $q.defer()
    if not user
      token = session.getToken()
      if token
        hash = md5.createHash(angular.toJson(token))
        item = {token: token, hash: hash}
        socket.emit "auth.byToken", item
        socket.once "auth.byToken."+hash, (result) ->
          if result and result.name and result.group
            user = {name:result.name,group:result.group}
            session.setUserName(result.name)
            d.resolve(user)
          else
            session.setToken("false")
            d.resolve(false)
      else
        d.resolve(false)
    else
      d.resolve(user)
    return d.promise
  this.setUser = (newUser) ->
    d = $q.defer()
    if newUser
      hash = md5.createHash(angular.toJson(newUser))
      item = {user: newUser, hash: hash}
      
      socket.emit "auth", item
      socket.once "auth."+hash, (result) ->
        if result and result.name and result.group
          user = {name:result.name,group:result.group}
          if result.token
            session.setToken(result.token)
          session.setUserName(result.name)
          d.resolve(user)
        else
          d.reject()
    else
      user = false
      d.resolve(user)
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
          userName: () -> return session.getUserName()
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
      if (user and user.group)
        d.resolve(inGroup(group))
      else
        this.tokenLogin()
        .then (success) ->
          if success
            d.resolve(inGroup(group))
          else
            showLoginModal(staticModal)
            .then (()->d.resolve(inGroup(group))), ()->d.resolve(false)
    return d.promise

  inGroup = (group) ->
    if user and user.group
      userGroup = user.group
    else
      userGroup = "all"
    should = groups.indexOf(group)
    actual = groups.indexOf(userGroup)
    return (should <= actual)

  this.inGroup = inGroup

  this.getUser = () ->
    return user
  return this

mod.service "institute", ($rootScope,$q,$modal,md5,session) ->
  this.showModal = (staticModal) -> 
    d = $q.defer()
    staticModal = false if not staticModal
    backdrop = if staticModal then "static" else true
    modalInstance = $modal.open {
      backdrop: backdrop
      keyboard: staticModal
      templateUrl: "indexInstitutes.html"
      controller: "institutesCtrl"        
      resolve: {
        activeInstitute: () -> return session.getActiveInstitute()
      }
    }
    modalInstance.result.then ((inst)->session.setActiveInstitute(inst)),(err)->d.reject(err)
    return d.promise
  return this
      

mod.service "session", ($rootScope,$cookieStore) ->
  activeInstitute = $cookieStore.get("activeInstitute")
  userName = $cookieStore.get("userName")
  token = $cookieStore.get("token")
  this.setActiveInstitute = (institute) ->
    activeInstitute = {name: institute.name, image: institute.image}
    $cookieStore.put("activeInstitute", institute)
    $rootScope.$$phase || $rootScope.$apply() 
  this.getActiveInstitute = () ->
    return activeInstitute  
  this.setUserName = (name) ->
    $cookieStore.put("userName", name)
    userName = name
  this.getUserName = () ->
    return userName
  this.setToken = (newToken) ->
    $cookieStore.put("token",newToken)
    token = newToken
  this.getToken = () ->
    return token
  return this
