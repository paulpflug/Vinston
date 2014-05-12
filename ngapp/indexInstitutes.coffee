angular.module("vinstonApp")
.controller "institutesCtrl", ($scope, $modalInstance,$location,auth,config, activeInstitute) -> 
  $scope.institutes = []
  $scope.ready = false
  $scope.activeInstitute = activeInstitute
  config.get("institutes").then (response) ->
    if response.success and response.content
      $scope.institutes = response.content 
      $scope.ready = true
    else
      auth.requirePermission("root",true)
      .then (success) ->
        if success
          $location.path("/root/appConfig")
          $modalInstance.dismiss()
        else
          window.location = "401.html"
  $scope.setInstitute = (inst) -> 
    $modalInstance.close(inst)
