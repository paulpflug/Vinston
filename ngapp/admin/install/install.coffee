"use strict"
window.socket = io.connect()

angular.module("installApp",[
  "globals"
  "ngCookies"
  "ngResource"
  "ngSanitize"
  "ngRoute"
  "oc.lazyLoad"
  "angular-md5"
  "toaster"
  "ui.bootstrap"
])
.controller "appCtrl", ($scope, $modal, $interval, $timeout, $q ,config,md5) ->
  socketConfig = io.connect("/installConfig")
  socketUsers = io.connect("/installUsers") 
  $scope.loaded = false  
  $scope.connectionTesting = false
  $scope.connectionTested = false
  $scope.connectionSaving = false
  $scope.connectionSaved = false
  $scope.connectionError = ""
  $scope.connectionInfo = ""
  $scope.userSaving = false
  $scope.userSaved = false
  $scope.userInfo = ""
  $scope.userName = ""
  $scope.userPassword= ""
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
  $scope.setUser = () ->
    d = $q.defer()
    $scope.userSaving = true
    $scope.userSaved = false
    user = {name: $scope.userName, password: $scope.userPassword}
    hash = md5.createHash(angular.toJson(user))
    socketUsers.emit "admin.set", {value: user, hash: hash}
    socketUsers.once "admin.set."+hash, (value) ->
      $scope.userSaved = true if value
      $scope.userInfo = "Admin gespeichert" if value
      $scope.userSaving = false
      $scope.$$phase || $scope.$apply() 
      d.resolve(value)
    $scope.$$phase || $scope.$apply()
    return d.promise
  socketConfig.on "configdone", () ->
    socketUsers = io.connect("/installUsers") 
  socketConfig.once "done", () ->
    console.log "test"
    $scope.userSaved = true
    $scope.userInfo = "Admin vorhanden"
    $scope.$$phase || $scope.$apply() 
  # initialize
  socketConfig.emit "mongoConnection"
  socketConfig.once "mongoConnection.data", (data) ->
    $scope.mongoConnection = data if data
    $scope.testConnection()
      .then((success) -> 
        $scope.connectionSaved = true if (success)
        $scope.loaded = true
        $scope.$$phase || $scope.$apply())