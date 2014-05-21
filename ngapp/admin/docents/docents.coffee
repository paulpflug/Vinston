angular.module("DocentsModule",["oc.lazyLoad",
   "infinite-scroll",
   "localytics.directives"])
.controller "docentsCtrl", ($scope, $filter, $q, $modal, semesterDataCollection, config) ->
  $scope.finished = false
  $scope.institutes = []
  $scope.docents = new semesterDataCollection {
    scope: $scope.$new()
    connection: "'docents.'+session.getActiveSemester().name"
    nameOfItem: "name"
    nameOfDatabase: "Dozent"
    useDiffs: true
    showDeleted: true
    }
  $scope.test = false
  $q.all([config.get("institutes"),$scope.docents.loaded])
  .then (results) ->
    if results[0] and results[0].success and results[0].content
      $scope.institutes = results[0].content
  .finally () ->  $scope.finished = true
 