"use strict"

angular.module("RoomsModule",["oc.lazyLoad",
   "infinite-scroll",
   "ui.select2", 
   "ui.bootstrap"])
.controller "RoomsCtrl", ($scope,$filter,socketData,globals) ->
  $scope.rooms = socketData
  $scope.rooms.setDatatype("rooms")
  $scope.rooms.filter.institute = ""
  $scope.rooms.count()
  $scope.institutes = []
  globals.institutes.then (data) ->
     $scope.institutes = data
  $scope.updateinst = () ->
    $scope.rooms.update()
    console.log "test"
    console.log $scope.rooms.filter
  $scope.instoptions = {
    allowClear:true
    width: "200px"
    placeholder: "Institut"
  }
  $scope.instsoptions = {
    width: "300px"
    placeholder: "Zusätzliche Institute"
    multiple: true
    simple_tags: true
    tags: () -> return $scope.institutes
  }