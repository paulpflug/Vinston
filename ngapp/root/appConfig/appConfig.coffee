"use strict"

angular.module("AppConfigModule",["oc.lazyLoad","ui.sortable"])
.controller "appConfigCtrl", ($scope, $q,configData, toaster) ->
  activeSetter = (name) ->
    return (newValue, oldValue) ->
      if newValue != oldValue
        $scope.active = name

  ready = () ->
    $scope.$watch("institutes.filter", activeSetter("institutes"), true)
    $scope.$watch("institutes.data", activeSetter("institutes"), true)
    $scope.$watch("semesters.filter", activeSetter("semesters"), true)
    $scope.$watch("semesters.data", activeSetter("semesters"), true)
    $scope.finished = true
  $scope.sortableOptions = (name) -> 
    return {
      placeholder: "placeholder"
      start: () -> activeSetter(name)
      stop: () -> $scope[name].save().catch($scope[name].reload)
    }
    
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

  $scope.institutes = new configData("institutes",$scope,{nameOfDatabase:"Institute"})
  $scope.semesters = new configData("semesters",$scope,{nameOfDatabase:"Semester"})
  $scope.finished = false  
  $scope.active = ""

  $q.all([$scope.institutes.loaded,$scope.semesters.loaded]).then(ready)

  