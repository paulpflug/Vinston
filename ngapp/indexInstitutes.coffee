angular.module("vinstonApp")
.controller "institutesCtrl", ($scope, $modalInstance,$location,auth,config, activeInstitute) -> 
  $scope.institutes = []
  $scope.ready = false
  $scope.activeInstitute = activeInstitute
  config.get("institutes").then (data) ->
    if data
      $scope.institutes = data 
      $scope.ready = true
    else
      auth.requirePermission("root",true)
      .then (success) ->
        console.log(success)
        if success
          $location.path("/admin/config")
          $modalInstance.close()
        else
          window.location = "401.html"
  $scope.setInstitute = (inst) -> 
    $modalInstance.close(inst)
