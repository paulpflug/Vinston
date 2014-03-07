"use strict"

angular.module("RoomsModule",["oc.lazyLoad"])
.controller "RoomsCtrl", ($scope,socket) ->
  socket.emit "rooms.read"
  socket.on "roomsData", (data) ->
        console.log "recieved data"
        $scope.rooms = data
  