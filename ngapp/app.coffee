"use strict"
window.socket = io.connect()

vinstonApp = angular.module("vinstonApp", [
  "socketData"
  "globals"
  "ngCookies"
  "ngResource"
  "ngSanitize"
  "ngRoute"
  "oc.lazyLoad"
  "angular-md5"
  "toaster"
  "ui.bootstrap"
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
                files: ['main.js']
        ]
    ).when("/rooms",
      templateUrl: "admin/rooms/rooms.html"
      controller: "RoomsCtrl"
      resolve: 
        test: ['$ocLazyLoad',
          ($ocLazyLoad) ->
            return $ocLazyLoad.load 
                name: 'RoomsModule',
                files: ['admin/rooms/rooms.js']
        ]
    ).otherwise redirectTo: "/"
]


