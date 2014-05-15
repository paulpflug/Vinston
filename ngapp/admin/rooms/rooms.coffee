"use strict"

angular.module("RoomsModule",["oc.lazyLoad",
   "infinite-scroll",
   "localytics.directives"])
.controller("roomsCtrl", ($scope, $filter,$q , $modal, semesterData, config) ->
  $scope.institutes = []
  $scope.rooms = new semesterData "rooms", $scope, {
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
    $scope.finished = true
)