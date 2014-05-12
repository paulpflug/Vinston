"use strict"

angular.module("AppConfigModule",["oc.lazyLoad","configData"])
.controller "appConfigCtrl", ($scope, $q,configData, config,toaster) ->
  activeSetter = (name) ->
    return (newValue, oldValue) ->
      if newValue != oldValue
        $scope.active = name

  ready = () ->
    $scope.$watch("institutes.filter", activeSetter("institutes"), true)
    $scope.$watch("institutes.data", activeSetter("institutes"), true)
    $scope.$watch("semester.filter", activeSetter("semesters"), true)
    $scope.loaded = true
  $scope.institutes = configData.setup("institutes")
  $scope.loaded = false  
  $scope.active = ""

  $q.all([$scope.institutes.loaded]).then(ready)

  $scope.testImg = (obj) ->
    $scope.institutes.setChanged(obj)
    img = new Image()
    obj.status = "loading"
    $scope.$$phase || $scope.$digest()
    img.addEventListener 'error', () ->
      obj.status = "danger"
      $scope.$$phase || $scope.$digest()
    img.addEventListener 'load', () ->
      obj.status = "success"
      $scope.$$phase || $scope.$digest()
    img.src = obj.image
