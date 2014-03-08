"use strict"
vinstonApp = angular.module("vinstonApp", [
  "ngCookies"
  "ngResource"
  "ngSanitize"
  "ngRoute"
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

vinstonApp.factory "socketData", ($rootScope,$filter) ->
  factory = {}
  factory.datatype = ""
  factory.data = []
  factory.filter = {}
  factory.busy = false
  factory.after = 0
  factory.totalCount = 0
  factory.status
  factory.setDatatype = (name) ->
    factory.datatype = name
    window.socket.on factory.datatype + ".status", (data) ->
      console.log "recieved status" + 
      factory.status = data
  factory.find = (cb, collection) ->
    if not factory.datatype
      console.log "first setDatatype"
      return
    window.socket.once factory.datatype + ".data", (data) ->
      console.log "recieved " + factory.datatype
      cb(data)
    console.log "requested " + factory.datatype
    window.socket.emit factory.datatype + ".find", collection  

  factory.next = () ->
    return if factory.busy
    factory.after = $filter("filter")(factory.data,factory.filter,"true").length
    if(factory.after<factory.totalCount or factory.after == 0 )
      factory.busy = true
      modifiedFilter = {}
      for key,value of factory.filter
        if typeof value == "string" and value != ""
          modifiedFilter[key] = { $regex: value }
      factory.find((data) ->
          factory.data.push d for d in data
          factory.busy = false
          factory.after += 20
          $rootScope.$$phase || $rootScope.$apply()
      , {options : {skip:factory.after,limit:20}, find: modifiedFilter}
      )
  factory.count = () ->
    if not factory.datatype
      console.log "first setDatatype"
      return
    window.socket.once factory.datatype + ".countdata", (data) ->
      factory.totalCount = $filter("filter")(data,factory.filter,"true").length

    modifiedFilter = {}    
    for key,value of factory.filter
      if typeof value == "string" and value != ""
        modifiedFilter[key] = { $regex: value }
    window.socket.emit factory.datatype + ".count", {find: modifiedFilter}  

  factory.setChanged = (arrayItem) ->
    console.log "found change "+arrayItem.name
    arrayItem.changed = true
  factory.updateFilter = () ->
    factory.count()
    for k,v of factory.filter
      if !v
        delete factory.filter[k]
    console.log(factory.filter)
    if $filter("filter")(factory.data,factory.filter,"true").length<20
      factory.next()
  factory.insert = () ->
    window.socket.emit factory.datatype + ".insert", factory.filter
    window.socket.once factory.datatype + ".insert.status", (data) ->
      if data[0]
        factory.filter = {}
        factory.data.push data[2]        
        $rootScope.$$phase || $rootScope.$apply()
  factory.update = (arrayItem) ->
    window.socket.emit factory.datatype + ".update", arrayItem
    window.socket.once factory.datatype + ".update.status", (data) ->
      if data[0]
        arrayItem.changed = false
        $rootScope.$$phase || $rootScope.$apply()
      else
        factory.find((data)->
            arrayItem = data
            $rootScope.$$phase || $rootScope.$apply()
          ,{find:{_id:arrayItem._id}})

  factory.remove = (arrayItem) ->
    window.socket.emit factory.datatype + ".remove", arrayItem._id
    window.socket.once factory.datatype + ".remove.status", (data) ->
      if data[0]
        index = factory.data.indexOf arrayItem
        factory.data.splice index,1
        $rootScope.$$phase || $rootScope.$apply()
  return factory

vinstonApp.service "globals", ($rootScope,$q) ->
  institutesData = []
  deferred = $q.defer();
  if not institutesData.length == 0
    deferred.resolve(institutesData)
  else    
    window.socket.once "institutes.data", (data) ->
      deferred.resolve(data);
      institutesData = data;
      $rootScope.$$phase || $rootScope.$apply();
    window.socket.emit "institutes"
  this.institutes = deferred.promise
  return this

window.socket = io.connect()
