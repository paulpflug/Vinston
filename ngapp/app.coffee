"use strict"
window.socket = io.connect()


vinstonApp = angular.module("vinstonApp", [
  "globals"
  "interfaces"
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

vinstonApp.config ["$routeProvider", ($routeProvider) ->
    String::capitalize = ->
      @substr(0, 1).toUpperCase() + @substr(1)
    $routeProvider.when "/",
      templateUrl: "main.html"
      controller: 'MainCtrl'
      resolve: 
        loadRoute: ($ocLazyLoad) ->
            return $ocLazyLoad.load 
                name: 'MainModule',
                files: ['main.js']

    .when "/:group/:function", 
      templateUrl: (params) ->
        g = "/"+params.group
        f = "/"+params.function
        return g+f+f+".html"
      resolve: 
        loadRoute: ($ocLazyLoad,$route,$q,$location,auth,toaster) ->
            d = $q.defer()
            params = $route.current.params
            g = "/"+params.group
            f = "/"+params.function
            auth.requirePermission(params.group)
            .then (success)->
              if success
                
                $ocLazyLoad.load 
                  name: params.function.capitalize()+"Module",
                  files: [g+f+f+".js"]
                .then () -> d.resolve()
              else
                d.reject()
                window.history.back()
                toaster.pop "error", "Unauthorisiert", "Sie haben nicht die nötige Berechtigung."
            return d.promise
    .otherwise redirectTo: "/"
]


vinstonApp.filter("isNot", () ->
  return (array,filter,property) ->
    if filter
      result = []
      for text in array
        t = text
        if property 
          if t[property]
            t = t[property]
          if filter[property]
            filter = filter[property]
        if t != filter
          result.push(text)
      return result
    else
      return array
)

vinstonApp.controller "isOpenCtrl", ($scope) ->
  $scope.isOpen = false
  $scope.dateOptions = {
    startingDay:1
  };

  $scope.toggle = ($event) ->
    $event.preventDefault();
    $event.stopPropagation();
    $scope.isOpen = !$scope.isOpen

