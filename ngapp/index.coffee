angular.module("vinstonApp")
.controller "appCtrl", ($scope ,$route,$q , session, auth, institute,semester) ->
  $scope.finished = false
  $scope.session = session
  $scope.auth = auth
  $scope.institute = institute
  $scope.semester = semester
  if not session.getActiveInstitute()
    institute.showModal(true)
  $scope.$on "$routeChangeSuccess", (ev, current) ->
    $scope.params = current.params
    $scope.$$phase || $scope.$digest()
  $q.all([session.loaded]).finally () -> 
    $scope.finished = true
    $scope.$$phase || $scope.$digest()
  
  