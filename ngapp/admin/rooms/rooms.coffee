"use strict"

angular.module("RoomsModule",["oc.lazyLoad",
   "infinite-scroll",
   "localytics.directives"])
.controller("roomsCtrl", ($scope, $filter, $modal, socketData, config) ->
  $scope.institutes = []
  config.get("institutes").then (data) ->
     $scope.institutes = data
  $scope.rooms = socketData
  $scope.rooms.setup "rooms", $scope, {
    nameOfItem: "name"
    nameOfDatabase: "Raum"
    useDiffs: true
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
)