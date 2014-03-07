"use strict"
vinstonApp = angular.module("vinstonApp", [
  "ngCookies"
  "ngResource"
  "ngSanitize"
  "ngRoute"
  "ui.utils"
  "ui.bootstrap"
  "oc.lazyLoad"
])

vinstonApp.config ['$ocLazyLoadProvider',
  ($ocLazyLoadProvider) ->
    $ocLazyLoadProvider.config
        asyncLoader: $script
]

vinstonApp.config ['$routeProvider',
  ($routeProvider) ->
    $routeProvider.when("/",
      templateUrl: "main.html"
      controller: 'MainCtrl'
      resolve: 
        test: ['$ocLazyLoad',
          ($ocLazyLoad) ->
            return $ocLazyLoad.load 
                name: 'MainModule',
                files: ['mainModule.js']
        ]
    ).when("/rooms",
      templateUrl: "admin/rooms/rooms.html"
      controller: 'RoomsCtrl'
      resolve: 
        test: ['$ocLazyLoad',
          ($ocLazyLoad) ->
            return $ocLazyLoad.load 
                name: 'RoomsModule',
                files: ['admin/rooms/roomsModule.js']
        ]
    ).otherwise redirectTo: "/"
]

vinstonApp.factory "socket", ($rootScope) ->
  socket = io.connect();
  return {
    on: (eventName, callback) -> 
      socket.on eventName, () ->   
        args = arguments;
        $rootScope.$apply () -> 
          callback.apply socket, args
    emit: (eventName, data, callback) ->
      socket.emit eventName, data, () -> 
        args = arguments;
        $rootScope.$apply () ->
          if callback
            callback.apply socket, args
    }

vinstonApp.service ""