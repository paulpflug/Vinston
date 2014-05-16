angular.module("ImportModule",["oc.lazyLoad","ui.ace"])
.controller "importCtrl", ($scope,semesterData) ->
  $scope.finished = false
  $scope.aceOptions = {
    mode: "json"
  }
  $scope.data = {text: ""}
  $scope.dataBackup = {}
  $scope.databases = ["rooms","docents"]
  $scope.selectedDatabase = ""
  $scope.selectdb = () ->
    db = new semesterData $scope.selectedDatabase,$scope
    if $scope.dataBackup[$scope.selectedDatabase]
      $scope.data = $scope.dataBackup[$scope.selectedDatabase]
    else
      $scope.data = {text: ""}
    $scope.dataBackup[$scope.selectedDatabase] = $scope.data
    console.log db
    console.log $scope.data
    #realdata = angular.fromJson($scope.data.text)
    #for d in realdata
    #  db.insert(d)
    #  .then (response) ->
    #    if response.success
    #       console.log response.content
  $scope.finished = true