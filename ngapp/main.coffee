"use strict"
angular.module("MainModule",["oc.lazyLoad"]).controller "MainCtrl", ($scope) ->
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
  window.socket.on "log", (data) ->
    console.log data

