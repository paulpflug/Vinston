window.socket = io()

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
    else
      $scope.route = false
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
          return d.promise
  .otherwise redirectTo: "/"

vinstonApp.filter "isNot", () ->
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


vinstonApp.filter "timeago", () -> 
  return (time, local, raw) -> 
    if (!time) 
      return "nie"

    if (!local) 
      (local = Date.now())
    

    if (angular.isDate(time)) 
      time = time.getTime();
    else if (typeof time == "string") 
      time = new Date(time).getTime();
    

    if (angular.isDate(local)) 
      local = local.getTime();
    else if (typeof local == "string") 
      local = new Date(local).getTime();

    if typeof time != 'number' || typeof local != 'number'
      return
    
    offset = Math.abs((local - time) / 1000)
    span = []
    MINUTE = 60
    HOUR = 3600
    DAY = 86400
    WEEK = 604800
    MONTH = 2629744
    YEAR = 31556926


    if (offset <= MINUTE)              
      span = [ '', if raw then 'jetzt' else 'weniger als einer Minute' ];
    else if (offset < (MINUTE * 60))   
      span = [ Math.round(Math.abs(offset / MINUTE)), 'min' ];
    else if (offset < (HOUR * 24))     
      span = [ Math.round(Math.abs(offset / HOUR)), 'h' ];
    else if (offset < (DAY * 7))       
      span = [ Math.round(Math.abs(offset / DAY)), 'd' ];
    else if (offset < (WEEK * 52))     
      span = [ Math.round(Math.abs(offset / WEEK)), 'w' ];
    else if (offset < (YEAR * 10))     
      span = [ Math.round(Math.abs(offset / YEAR)), 'Y' ];
    else                               
      span = [ '', 'sehr langer Zeit' ];
    span = span.join(' ');
    if (raw == true) 
      return span;
    return if time <= local then "vor " + span else "in " + span;





vinstonApp.controller "isOpenCtrl", ($scope) ->
  $scope.isOpen = false
  $scope.dateOptions = {
    startingDay:1
  };

  $scope.toggle = ($event) ->
    $event.preventDefault();
    $event.stopPropagation();
    $scope.isOpen = !$scope.isOpen

vinstonApp.controller "sortCtrl", ($scope) ->
  types = {}
  prettys = {}
  getName = (name) ->
    if name.charAt(0) == "-"
      return name.slice(1)
    else
      return name
  $scope.getPretty = (name) ->
    name = getName(name)
    return prettys[name]
  
  $scope.getPopover = (model,name,pretty) ->
    name = getName(name)
    prettys[name] = pretty
    index = model.indexOf(name)
    if index > -1
      return "Abwärts sortieren"
    else
      return "Aufwärts sortieren"
  
  $scope.getClass = (model,name,type) ->
    name = getName(name)
    if type and type != "" and type != "undefined"
      type = "-"+type 
      types[name] = type
    else
      type = types[name]
      if not type
        type = ""
    index = model.indexOf(name)
    if index > -1
      return "fa-sort"+type+"-desc"
    else
      return "fa-sort"+type+"-asc"
      
  $scope.toggleSort = (model,name) ->
    name = getName(name)
    index = model.indexOf(name)
    if index > -1
      model[index] = "-"+name
    else
      index = model.indexOf("-"+name)
      if index > -1
        model[index] = name
      else
        model.push name
  $scope.remove = (model,name) ->
    console.log name
    
    index = model.indexOf(name)
    if index > -1
      model= model.splice(index,1)
    else
      index = model.indexOf("-"+name)
      if index > -1
        model= model.splice(index,1)