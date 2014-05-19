angular.module('interfaces')
.service "config", ($rootScope,$q,generate,clean) ->
  socket = io.connect("/config")
  getter = {}
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
    return getter[name] if getter[name]
    d = $q.defer()
    getter[name] = d.promise
    console.log config[name]
    if config[name] and config[name].success and !update
      d.resolve(config[name])
      delete getter[name]
      $rootScope.$$phase || $rootScope.$apply() 
    else  
      token = generate.token()
      request = {token: token}
      socket.emit name + ".get", request
      socket.once name + ".get."+ token, (response) ->
        if response
          d.resolve(response)
          delete getter[name]
          if response.success           
            updateItem name, response
        else
          d.reject() 
          delete getter[name]      
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
      request = {content: clean.object(content), token: token} 
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