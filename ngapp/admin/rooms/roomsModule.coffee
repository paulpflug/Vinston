"use strict"

angular.module("RoomsModule",["oc.lazyLoad",
   "infinite-scroll",
   "localytics.directives", 
   "ui.bootstrap"])
.controller "RoomsCtrl", ($scope,$filter,socketData,globals) ->
  $scope.rooms = socketData
  $scope.rooms.setDatatype("rooms")
  $scope.rooms.count()
  $scope.institutes = []
  globals.institutes.then (data) ->
     $scope.institutes = data
