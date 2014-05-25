angular.module "AllModule"
.controller "freeRoomCtrl", ($scope,$q, semesterData) ->
  $scope.finished = false
  $scope.institutes = []
  $scope.rooms = new semesterData {
    scope: $scope.$new()
    connection: "'rooms.'+session.getActiveSemester().name"
    nameOfItem: "name"
    nameOfDatabase: "Raum"
    query: {find: {"freeToUse":true},fields: "name"}
    }

  $scope.courses = new semesterData {
    scope: $scope.$new()
    connection: "'courses.'+session.getActiveSemester().name"
    nameOfItem: "name"
    nameOfDatabase: "Veranstaltung"
    query: {fiels: "lessons"}
    }
  $q.all([$scope.rooms.loaded,$scope.courses])
  .finally () ->  
    $scope.finished = true 
    console.log $scope.rooms.data
