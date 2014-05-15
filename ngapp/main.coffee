"use strict"
angular.module("MainModule",["oc.lazyLoad"]).controller "MainCtrl", ($scope,semesterData) ->
  $scope.awesomeThings = [
    "HTML5 Boilerplate"
  ]
  $scope.rooms = [{
      name: "test",
      institute: "testI"
    },{
      name: "test2",
      institute: "testI"
    }
  ]
  $scope.rooms = new semesterData "rooms", $scope, {
    nameOfItem: "name"
    nameOfDatabase: "Raum"
    useDiffs: true
    }
  $scope.rooms.find(console.log,{find:{deleted:true},fields:"version name"})
  window.socket.on "log", (data) ->
    console.log data

