angular.module("vinstonApp")
.controller "appCtrl", ($scope, session, auth, institute) ->
  $scope.session = session
  $scope.auth = auth
  $scope.institute = institute
  if not session.getActiveInstitute()
    institute.showModal(true)
  auth.tokenLogin().finally () ->
    $scope.loaded = true