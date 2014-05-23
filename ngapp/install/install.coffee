"use strict"
window.socket = io.connect()

angular.module("installApp",[
  "globals"
  "interfaces"
  "ngCookies"
  "ngResource"
  "ngSanitize"
  "ngRoute"
  "oc.lazyLoad"
  "angular-md5"
  "toaster"
  "ui.bootstrap"
])
.controller "appCtrl", ($scope, $modal, $interval, $timeout, $q ,generate,config) ->
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
      token = generate.token()
      $scope.connectionTesting = true
      socketConfig.emit "mongoConnection.test", {content: $scope.mongoConnection, token: token}    
      socketConfig.once "mongoConnection.test." + token, (response) ->
        if response and response.content 
          if testedCount == $scope.testedCount
            $scope.connectionInfo = ""
            $scope.connectionError = ""
            if response.success
              $scope.connectionTested = true
              $scope.connectionInfo = response.content
            else
              $scope.connectionError = response.content
            $scope.connectionTesting = false
            $scope.$$phase || $scope.$apply()
          d.resolve(response.success)
      $scope.$$phase || $scope.$apply()
    else
      d.resolve()
    return d.promise
  $scope.setConnection = () ->
    d = $q.defer()
    $scope.connectionSaving = true
    $scope.connectionSaved = false
    token = generate.token()
    socketConfig.emit "mongoConnection.set", {content: $scope.mongoConnection, token: token}
    socketConfig.once "mongoConnection.set." + token, (response) ->
      if response.success
        $scope.connectionSaved = true
      else
        $scope.connectionTested = false
      $scope.connectionSaving = false
      $scope.$$phase || $scope.$apply() 
      d.resolve(response)
    $scope.$$phase || $scope.$apply()
    return d.promise
  $scope.setUser = () ->
    d = $q.defer()
    $scope.userSaving = true
    $scope.userSaved = false
    user = {name: $scope.userName, password: $scope.userPassword}
    token = generate.token()
    socketUsers.emit "root.set", {content: user, token: token}
    socketUsers.once "root.set." + token, (response) ->
      if response and response.success
        $scope.userSaved = true
        $scope.userInfo = "Root gespeichert"
        $scope.userSaving = false
        $scope.$$phase || $scope.$apply() 
      d.resolve(response)
    $scope.$$phase || $scope.$apply()
    return d.promise
  socketConfig.on "configdone", () ->
    socketUsers = io.connect("/installUsers") 
  socketConfig.once "finished", () ->
    $scope.userSaved = true
    $scope.userInfo = "Root vorhanden"
    $scope.$$phase || $scope.$apply() 
  # initialize
  token = generate.token()
  socketConfig.emit "mongoConnection.get", {token:token}
  socketConfig.once "mongoConnection.get." + token, (response) ->
    if response.success
      $scope.mongoConnection = response.content
      $scope.testConnection()
        .then((success) -> 
          $scope.connectionSaved = true if (success)
          $scope.loaded = true
          $scope.$$phase || $scope.$apply())