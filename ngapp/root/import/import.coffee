angular.module("ImportModule",["oc.lazyLoad","ui.ace"])
.controller "importCtrl", ($scope,semesterData) ->
  $scope.finished = false
  $scope.aceOptions = {
    mode: "json"
  }
  $scope.data = ""
  $scope.databases = ["rooms","docents"]
  $scope.selectedDatabase = ""
  $scope.selectdb = () ->
    $scope.db = new semesterData $scope.selectedDatabase,$scope
    console.log $scope.db
    console.log $scope.data
  $scope.finished = true