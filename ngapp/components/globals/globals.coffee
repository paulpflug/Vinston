mod = angular.module('globals', ["ngCookies"])

mod.service "clean", () ->
  keys = ["changed","busy","status","statusText","$$hashKey"]
  deleteKeys = (obj) ->
    for key in keys
      delete obj[key]
    return obj
  return (arg) ->
    if angular.isArray(arg)
      newArg = []
      for obj in arg
        if angular.isObject(obj)
          newArg.push(deleteKeys(obj))
      arg = newArg
    else
      if angular.isObject(arg)
        arg = deleteKeys(arg)
    return arg

mod.service "generate", () ->
  this.token = () ->
    number = 0
    while number == 0 or number == 1
      number = Math.random()
    return number.toString(36).substr(2)
  
  ids = []
  this.id = (length) ->
    length = 6 if not length
    index = 0
    while index > -1
      id = this.token().substr(0,length)
      index = ids.indexOf(id)
    ids.push(id)
    return id

  return this

mod.service "config", ($rootScope,$q,generate,clean) ->
  socket = io.connect("/config")
  getter = false
  config = {}
  types = {}
  updatecbs = []
  socket.on "update", (name) ->
    if config[name]
      get(name,true)
      .then (response) ->
        if response.success
          console.log updatecbs
          for cb in updatecbs
            cb()
  updateItem = (name,response) ->
    config[name] = response
    $rootScope.$$phase || $rootScope.$apply()
  this.addUpdatecb = (cb) ->
    updatecbs.push(cb)
    return updatecbs.indexOf(cb)
  this.removeUpdatecb = (index) ->
    updatecbs.splice(index,1)
  get = (name,update) ->
    return getter if getter
    d = $q.defer()
    getter = d.promise
    if config[name] and config[name].length > 0 and !update
      d.resolve(config[name])
      getter = false
      $rootScope.$$phase || $rootScope.$apply() 
    else  
      token = generate.token()
      request = {token: token}
      socket.emit name + ".get", request
      socket.once name + ".get."+ token, (response) ->
        if response
          d.resolve(response)
          getter = false
          if response.success           
            updateItem name, response
        else
          d.reject() 
          getter = false       
    return d.promise
  this.get = get

  this.getType = (name) ->
    d = $q.defer()
    if types[name]
      d.resolve(types[name])
    else  
      token = generate.token()
      request = {token: token}
      socket.emit name + ".type", request
      socket.once name + ".type."+ token, (response) ->
        if response
          d.resolve(response)
          if response.success           
            types[name] = response
        else
          d.reject()        
    return d.promise

  this.set = (name,content) ->
    d = $q.defer()
    if content 
      token = generate.token()
      request = {content: clean(content), token: token} 
      socket.emit name + ".set", request
      socket.once name + ".set." + token, (response) ->
        if response
          d.resolve(response)
          if response.success            
            updateItem name, response
        else
          d.reject()   
    else
      d.reject()
    return d.promise


  this.test = (name,content) ->
    d = $q.defer()
    if content
      token = generate.token()
      request = {content: content, token: token} 
      socket.emit name + ".test", request
      socket.once name + ".test." + token, (response) ->
        if response
          d.resolve(response)
        else
          d.reject()   
    else
      d.reject()
    return d.promise
    
  return this

mod.service "auth", ($rootScope,$q,$modal,generate,session) ->
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
  activeInstitute = "" if not activeInstitute
  user = $cookieStore.get("user")
  user = {} if not user
  this.setActiveInstitute = (institute) ->
    activeInstitute = {name: institute.name, image: institute.image}
    $cookieStore.put("activeInstitute", institute)
    $rootScope.$$phase || $rootScope.$apply() 
  this.getActiveInstitute = () ->
    return activeInstitute
  this.setUser = (newUser) ->
    $cookieStore.put("user", newUser)
    user = newUser
  this.getUser = () ->
    return user
  return this
