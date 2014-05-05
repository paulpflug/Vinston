angular.module("vinstonApp")
.controller "loginCtrl", ($scope, $modalInstance, auth, userName) ->
  $scope.user = {name : userName, password : ""}
  $scope.error = ""
  $scope.loginIn = false
  $scope.login = () -> 
    if $scope.user.name and $scope.user.password
      $scope.loginIn = true
      auth.setUser($scope.user).then $modalInstance.close,() ->
        $scope.password = ""
        $scope.error = "Fehlgeschlagen"
      .finally () -> $scope.loginIn = false
