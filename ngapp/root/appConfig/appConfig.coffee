"use strict"

angular.module("AppConfigModule",["oc.lazyLoad"])
.controller "appConfigCtrl", ($scope, $q,md5, config,toaster) ->
  setInstitutesActive = (newValue, oldValue) ->
    if newValue != oldValue
      $scope.active = "institutes"
  ready = () ->
    $scope.$watch("active =='institutes' ? true : institute.filter", setInstitutesActive, true)
    $scope.$watch("active =='institutes' ? true : institutes", setInstitutesActive, true)
    $scope.loaded = true
  $scope.loaded = false  
  $scope.active = ""
  $scope.institute.filter = {}
  $scope.institute.disabled = false
  config.get("institutes").then (institutes) ->
    $scope.institutes = institutes    
    $scope.$$phase || $scope.$digest()
    ready()
  $scope.setChanged = (obj) ->
    obj.changed = true
  $scope.testImg = (obj) ->
    $scope.setChanged(obj)
    img = new Image()
    obj.status = "loading"
    $scope.$$phase || $scope.$digest()
    img.addEventListener 'error', () ->
      obj.status = "err"
      $scope.$$phase || $scope.$digest()
    img.addEventListener 'load', () ->
      obj.status = "success"
      $scope.$$phase || $scope.$digest()
    img.src = obj.image