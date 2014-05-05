"use strict"

angular.module("ServerConfigModule",["oc.lazyLoad",
   "infinite-scroll",
   "localytics.directives", 
   "ui.bootstrap"])
.controller "serverConfigCtrl", ($scope, $q,md5, config) ->
  socketConfig = io.connect("/config")
  $scope.loaded = false  
  $scope.connectionTesting = false
  $scope.connectionTested = false
  $scope.connectionSaving = false
  $scope.connectionSaved = false
  $scope.connectionError = ""
  $scope.connectionInfo = ""
  $scope.testedCount = 0
  $scope.testConnection = () ->
    d = $q.defer()
    $scope.testedCount++
    testedCount = $scope.testedCount
    $scope.connectionTested = false
    $scope.connectionSaved = false
    $scope.userSaved = false
    if $scope.mongoConnection      
      hash = md5.createHash($scope.mongoConnection)
      $scope.connectionTesting = true
      socketConfig.emit "mongoConnection.test", {value: $scope.mongoConnection, hash: hash}    
      socketConfig.once "mongoConnection.test."+hash, (data) ->
        if data 
          if testedCount == $scope.testedCount
            $scope.connectionInfo = ""
            $scope.connectionError = ""
            if data.success and data.info 
              $scope.connectionTested = true
              $scope.connectionInfo = data.info
            if not data.success and data.err
              $scope.connectionError = data.err
            $scope.connectionTesting = false
            $scope.$$phase || $scope.$apply()
          d.resolve(data.success)
      $scope.$$phase || $scope.$apply()
    else
      d.resolve()
    return d.promise
  $scope.setConnection = () ->
    d = $q.defer()
    $scope.connectionSaving = true
    $scope.connectionSaved = false
    hash = md5.createHash($scope.mongoConnection)
    socketConfig.emit "mongoConnection.set", {value: $scope.mongoConnection, hash: hash}
    socketConfig.once "mongoConnection.set."+hash, (value) ->
      if value
        $scope.connectionSaved = true
      else
        $scope.connectionTested = false
      $scope.connectionSaving = false
      $scope.$$phase || $scope.$apply() 
      d.resolve(value)
    $scope.$$phase || $scope.$apply()
    return d.promise
  # initialize
  config.get "mongoConnection"
  .then (data)->
    $scope.mongoConnection = data if data
    $scope.testConnection()
      .then((success) -> 
        $scope.connectionSaved = true if (success)
        $scope.loaded = true
        $scope.$$phase || $scope.$apply())