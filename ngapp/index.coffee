window.socket = io.connect()

vinstonApp = angular.module "vinstonApp", [
  "globals"
  "interfaces"
  "ngCookies"
  "ngResource"
  "ngSanitize"
  "ngRoute"
  "oc.lazyLoad"
  "toaster"
  "ui.bootstrap"
]

vinstonApp.controller "appCtrl", ($scope ,$route,$q , session, auth, institute,semester) ->
  $scope.finished = false
  $scope.session = session
  $scope.auth = auth
  $scope.institute = institute
  $scope.semester = semester
  if not session.getActiveInstitute()
    institute.showModal(true)
  $scope.$on "$routeChangeSuccess", (ev, current) ->
    params = current.params
    if nav and params.group and params.function and nav[params.group] and nav[params.group].functions and nav[params.group].functions[params.function]
      item = nav[params.group].functions[params.function]
      $scope.route = {pretty: item.pretty, icon: item.icon}
      $scope.$$phase || $scope.$digest()
  $q.all([session.loaded]).finally () -> 
    $scope.finished = true
    $scope.$$phase || $scope.$digest()
  

vinstonApp.config ($ocLazyLoadProvider) ->
  $ocLazyLoadProvider.config
      asyncLoader: $script


vinstonApp.config ($routeProvider) ->
  String::capitalize = ->
    @substr(0, 1).toUpperCase() + @substr(1)
  $routeProvider.when "/",
    templateUrl: "main.html"
  .when "/:group/:function", 
    templateUrl: (params) ->
      g = "/"+params.group
      f = "/"+params.function
      return g+f+f+".html"
    resolve: 
      loadRoute: ($ocLazyLoad,$route,$q,$location,auth,toaster) ->
          d = $q.defer()
          params = $route.current.params
          if nav and nav[params.group] and nav[params.group].functions and nav[params.group].functions[params.function]
            g = "/"+params.group
            f = "/"+params.function
            auth.requirePermission(params.group)
            .then (success)->
              if success and modules[params.group] and modules[params.group].files
                if modules[params.group].path
                  files = []
                  path = modules[params.group].path
                  for file in modules[params.group].files
                    files.push path + file
                else
                  files = modules[params.group].files
                $ocLazyLoad.load 
                  name: params.group.capitalize()+"Module",
                  files: files
                .then () -> d.resolve()
              else
                d.reject()
                window.history.back()
                toaster.pop "error", "Unauthorisiert", "Sie haben nicht die nötige Berechtigung."
          else
            d.reject()
          return d.promise
  .otherwise redirectTo: "/"

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

