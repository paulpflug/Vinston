angular.module "RootModule"
.controller "importCtrl", ($scope,semesterData) ->
  $scope.finished = false
  $scope.aceOptions = {
    mode: "json"
  }
  db = new semesterData {
    scope: $scope.$new()
    connection: "$scope.selectedDatabase"
      }
  $scope.data = {text: ""}
  $scope.dataBackup = {}
  $scope.databases = ["rooms","docents"]
  $scope.selectedDatabase = ""
  $scope.selectdb = () ->
    if $scope.dataBackup[$scope.selectedDatabase]
      $scope.data = $scope.dataBackup[$scope.selectedDatabase]
    else
      $scope.data = {text: ""}
    $scope.dataBackup[$scope.selectedDatabase] = $scope.data
    #realdata = angular.fromJson($scope.data.text)
    #for d in realdata
    #  db.insert(d)
    #  .then (response) ->
    #    if response.success
    #       console.log response.content
  $scope.finished = true