angular.module "AdminModule"
.controller "audiencesCtrl", ($scope, $q , $modal,session, semesterDataCollection, config) ->
  $scope.finished = false
  $scope.institutes = []
  $scope.terms = ["1","2","3","4","5","6","7","8","9","10"]
  $scope.audiences = new semesterDataCollection {
    scope: $scope.$new()
    connection: "'audiences.'+session.getActiveSemester().name"
    nameOfItem: "name"
    nameOfDatabase: "Zielgruppen"
    useDiffs: true
    showDeleted: true
    }

  $q.all([config.get("institutes"),$scope.audiences.loaded])
  .then (results) ->
    if results[0] and results[0].success and results[0].content
      $scope.institutes = results[0].content
  .finally () ->  $scope.finished = true 
