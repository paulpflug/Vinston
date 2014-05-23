angular.module "AdminModule"
.controller "roomsCtrl", ($scope, $filter,$q , $modal,session, semesterDataCollection, config) ->
  $scope.finished = false
  $scope.institutes = []
  $scope.rooms = new semesterDataCollection {
    scope: $scope.$new()
    connection: "'rooms.'+session.getActiveSemester().name"
    nameOfItem: "name"
    nameOfDatabase: "Raum"
    useDiffs: true
    showDeleted: true
    }
  $scope.showHistory = (room) -> 
    $scope.rooms.showHistory(room)
    modalInstance = $modal.open {
      templateUrl: "admin/rooms/roomsHistory.html"
      controller: ($scope, $modalInstance, rooms) -> 
        $scope.rooms = rooms
        $scope.useOldItem = (room) ->
          $scope.rooms.useOldItem(room)
          $modalInstance.close()
      resolve: {
        rooms: () -> 
          return $scope.rooms          
      }
    }
  $q.all([config.get("institutes"),$scope.rooms.loaded])
  .then (results) ->
    if results[0] and results[0].success and results[0].content
      $scope.institutes = results[0].content
  .finally () ->  $scope.finished = true 
