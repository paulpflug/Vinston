angular.module("vinstonApp")
.controller "appCtrl", ($scope ,$route , session, auth, institute) ->
  $scope.session = session
  $scope.auth = auth
  $scope.institute = institute
  if not session.getActiveInstitute()
    institute.showModal(true)
  $scope.$on "$routeChangeSuccess", (ev, current) ->
    $scope.params = current.params
    $scope.$$phase || $scope.$digest()

  $scope.loaded = true
  