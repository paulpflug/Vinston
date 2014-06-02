angular.module('interfaces')
.factory "config", ($rootScope,$q,generate,clean) ->
  new class config
    constructor: () ->
      self = @
      d = $q.defer()
      @socket = io("/config")
      @loaded = d.promise
      @socket.on "connect", () -> d.resolve() 
      @getter = {}
      @config = {}
      @types = {}
      @updatecbs = []
      @socket.on "update", (name) ->
        if config[name]
          self.get(name,true)
          .then (response) ->
            if response.success
              for cb in self.updatecbs
                cb()
    updateItem: (name,response) ->
      self = @
      self.config[name] = response
      $rootScope.$$phase || $rootScope.$apply()
    addUpdatecb: (cb) ->
      self = @
      self.updatecbs.push(cb)
      return self.updatecbs.indexOf(cb)
    removeUpdatecb: (index) ->
      self = @
      self.updatecbs.splice(index,1)
    get: (name,update) ->
      self = @
      return self.getter[name] if self.getter[name]
      d = $q.defer()
      self.getter[name] = d.promise
      if self.config[name] and self.config[name].success and !update
        d.resolve(self.config[name])
        delete self.getter[name]
        $rootScope.$$phase || $rootScope.$apply() 
      else 
        self.loaded.then () -> 
          token = generate.token()
          request = {token: token}
          self.socket.emit name + ".get", request
          self.socket.once name + ".get."+ token, (response) ->
            if response
              d.resolve(response)
              delete self.getter[name]
              if response.success           
                self.updateItem name, response
            else
              d.reject() 
              delete self.getter[name]      
      return d.promise
    getType: (name) ->
      self = @
      d = $q.defer()
      if self.types[name]
        d.resolve(self.types[name])
      else 
        self.loaded.then () ->  
          token = generate.token()
          request = {token: token}
          self.socket.emit name + ".type", request
          self.socket.once name + ".type."+ token, (response) ->
            if response
              d.resolve(response)
              if response.success           
                self.types[name] = response
            else
              d.reject()        
      return d.promise

    set: (name,content) ->
      self = @
      d = $q.defer()
      if content 
        self.loaded.then () -> 
          token = generate.token()
          request = {content: clean.object(content), token: token} 
          self.socket.emit name + ".set", request
          self.socket.once name + ".set." + token, (response) ->
            if response
              d.resolve(response)
              if response.success            
                self.updateItem name, response
            else
              d.reject()   
      else
        d.reject()
      return d.promise


    test: (name,content) ->
      self = @
      d = $q.defer()
      if content
        self.loaded.then () -> 
          token = generate.token()
          request = {content: content, token: token} 
          self.socket.emit name + ".test", request
          self.socket.once name + ".test." + token, (response) ->
            if response
              d.resolve(response)
            else
              d.reject()   
      else
        d.reject()
      return d.promise