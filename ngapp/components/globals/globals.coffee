mod = angular.module('globals', ["ngCookies"])

mod.service "config", ($rootScope,$q) ->
  socket = io.connect("/config")
  config = {}
  this.get = (name) ->
    deferred = $q.defer()
    if config[name] and config[name].length > 0
      deferred.resolve(config[name])
      $rootScope.$$phase || $rootScope.$apply() 
    else  
      socket.once name + ".data", (data) ->
        deferred.resolve(data)
        config[name] = data
        $rootScope.$$phase || $rootScope.$apply() 
        return
      socket.emit name      
    return deferred.promise
  return this


mod.service "session", ($rootScope,$cookieStore) ->
  activeInstitute = $cookieStore.get("activeInstitute")
  this.setActiveInstitute = (institute) ->
    activeInstitute = {name: institute.name, image: institute.image}
    $cookieStore.put("activeInstitute", institute)
    $rootScope.$$phase || $rootScope.$apply() 
  this.getActiveInstitute = () ->
    return activeInstitute   
  return this