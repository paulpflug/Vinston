"use strict"

angular.module("RoomsModule",["oc.lazyLoad",
   "infinite-scroll",
   "localytics.directives", 
   "ui.bootstrap"])
.controller("RoomsCtrl", ($scope, $filter, $modal, socketData, globals) ->
  $scope.institutes = []
  globals.institutes.then (data) ->
     $scope.institutes = data
  $scope.rooms = socketData
  $scope.rooms.setup "rooms", {
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