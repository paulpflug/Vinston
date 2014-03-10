"use strict"

angular.module("RoomsModule",["oc.lazyLoad",
   "infinite-scroll",
   "localytics.directives", 
   "ui.bootstrap"])
.controller "RoomsCtrl", ($scope,$filter,socketData,globals,toaster) ->
  $scope.rooms = socketData
  $scope.rooms.setup "rooms", "name"
  $scope.rooms.count()
  $scope.institutes = []
  globals.institutes.then (data) ->
     $scope.institutes = data