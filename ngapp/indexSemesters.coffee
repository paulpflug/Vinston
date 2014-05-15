angular.module("vinstonApp")
.controller "semestersCtrl", ($scope, $modalInstance,$location,config, activeSemester) -> 
  $scope.semesters = []
  $scope.ready = false
  $scope.activeSemester = activeSemester
  config.get("semesters").then (response) ->
    if response.success and response.content
      $scope.semesters = response.content 
      $scope.ready = true
    else
      $modalInstance.dismiss()
  $scope.setSemester = (semester) -> 
    $modalInstance.close(semester)
