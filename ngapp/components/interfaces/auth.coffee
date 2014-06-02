angular.module('interfaces')
.factory "auth", ($rootScope,$q,$modal,generate,session) ->
  new class auth
    constructor: () ->
      self = @
      d = $q.defer()
      @socket = io("/auth")
      @loaded = d.promise
      @socket.on "connect", () -> d.resolve() 
      @authenticated = false
      @groups = ["all","student","docent","admin","root"] 
    tokenLogin: () ->
      self = @
      d = $q.defer()
      user = session.getUser()
      if not self.authenticated
        if user and user.token
          self.loaded.then () -> 
            token = generate.token()
            item = {content: user.token, token: token}
            self.socket.emit "auth.byToken", item
            self.socket.once "auth.byToken."+token, (response) ->
              if response.success and response.content and response.content.name and response.content.group
                user = {name:response.content.name,group:response.content.group,token:user.token}
                self.authenticated = true
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
    setUser: (newUser) ->
      self = @
      reject = () ->
        self.authenticated = false
        session.setUser(false)
        d.reject()
      d = $q.defer()
      if newUser
        self.loaded.then () -> 
          token = generate.token()
          item = {content: newUser, token: token}  
          self.socket.emit "auth", item
          self.socket.once "auth."+token, (response) ->
            if response.success and response.content and response.content.name and response.content.group and response.content.token
              user = {name:response.content.name,group:response.content.group,token:response.content.token}
              self.authenticated = true
              session.setUser(user)
              d.resolve(user)
            else
              reject()
      else
        reject()
      return d.promise

    showLoginModal: (staticModal) ->
      self = @
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

    requirePermission: (group,staticModal) ->
      self = @
      d = $q.defer()
      if group == "all"
        d.resolve(true)
      else
        user = session.getUser()
        if (user and user.group and self.authenticated)
          d.resolve(self.inGroup(group,user))
        else
          self.tokenLogin()
          .then ((user) -> d.resolve(self.inGroup(group,user))), (() ->
            self.showLoginModal(staticModal)
            .then ((user)->d.resolve(self.inGroup(group,user))), ()->d.resolve(false))
      return d.promise

    inGroup: (group,user) ->
      self = @
      return false if not group
      if not user
        user = session.getUser()
      if user and user.group
        userGroup = user.group
      else
        userGroup = "all"
      should = self.groups.indexOf(group)
      actual = self.groups.indexOf(userGroup)
      return (should <= actual)