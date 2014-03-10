"use strict"
vinstonApp = angular.module("vinstonApp", [
  "ngCookies"
  "ngResource"
  "ngSanitize"
  "ngRoute"
  "oc.lazyLoad"
  "angular-md5"
  "toaster"
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

vinstonApp.factory "socketData", ($rootScope,$filter,md5,toaster) ->
  factory = {}
  factory.disabled = true
  factory.datatype = ""
  factory.nameOfItem = "name"
  factory.data = []
  factory.filter = {}
  factory.busy = false
  factory.after = 0
  factory.totalCount = 0
  factory.socket
  factory.setup = (datatype, nameOfItem) ->
    factory.datatype = datatype
    factory.nameOfItem = nameOfItem
    window.socket.emit "subscribe", datatype
    window.socket.on factory.datatype + ".inserted", (data) ->
      if(factory.after >= factory.totalCount)
        factory.data.push data
        toaster.pop "info", "Neuer Raum", factory.getName(data) + " wurde hinzugefügt."   
        $rootScope.$$phase || $rootScope.$apply()
    window.socket.on factory.datatype + ".updated", (newdata) ->
        olddata = $.grep(factory.data, (e) -> return e._id == newdata._id );
        if olddata and olddata[0] 
          olddata = olddata[0]         
          s = factory.getName(olddata) + " wurde" 
          if factory.getName(newdata) != factory.getName(olddata)
            s += " zu "+ factory.getName(newdata)
          s+= " verändert."
          toaster.pop "info", "Raum geändert", s   
          index = factory.data.indexOf olddata
          factory.data[index] = newdata
          $rootScope.$$phase || $rootScope.$apply()
    window.socket.on factory.datatype + ".deleted", (id) ->
        olddata = $.grep(factory.data, (e) -> return e._id == id );
        if olddata and olddata[0]     
          olddata = olddata[0]     
          toaster.pop "info", "Raum gelöscht", factory.getName(olddata) + " wurde gelöscht"   
          index = factory.data.indexOf olddata
          factory.data.splice index,1
          $rootScope.$$phase || $rootScope.$apply()
  factory.getName = (arrayItem) ->
    if arrayItem[factory.nameOfItem]
      return arrayItem[factory.nameOfItem]
    else
      return arrayItem["_id"]
  factory.setChanged = (arrayItem) ->
    arrayItem.changed = true

  factory.find = (cb, collection) ->
    hash = md5.createHash(angular.toJson(collection))
    window.socket.emit factory.datatype + ".find", {collection: collection, hash: hash}
    console.log "requested " + factory.datatype
    window.socket.once factory.datatype + ".data." + hash, (data) ->
      console.log "recieved " + factory.datatype
      cb(data)
    
  factory.next = () ->
    return if factory.busy
    factory.after = $filter("filter")(factory.data,factory.filter,"true").length
    console.log factory.after
    console.log factory.totalCount
    if(factory.after< factory.totalCount)
      factory.busy = true
      modifiedFilter = {}
      for key,value of factory.filter
        if typeof value == "string" and value != ""
          modifiedFilter[key] = { $regex: value }
      factory.find((data) ->
          factory.disabled = false
          for d in data
            index = factory.data.indexOf d
            if index > -1
              factory.data = []
              toaster.pop "error", "Inkonsistent", "Die Daten sind inkonsistent - lade neu"
              $rootScope.$$phase || $rootScope.$apply()
              return
            else
              factory.data.push d
          factory.busy = false
          factory.after += 20
          $rootScope.$$phase || $rootScope.$apply()
      , {options : {skip:factory.after,limit:20}, find: modifiedFilter}
      )
    else
      $rootScope.$$phase || $rootScope.$apply()

  factory.count = () ->
    modifiedFilter = {}    
    for key,value of factory.filter
      if typeof value == "string" and value != ""
        modifiedFilter[key] = { $regex: value }
      if typeof value == "object" and value.length >0
        modifiedFilter[key] = value
    collection = {find: modifiedFilter}
    hash = md5.createHash(angular.toJson(collection))
    window.socket.emit factory.datatype + ".count", {collection: collection, hash:hash} 
    window.socket.once factory.datatype + ".countdata." + hash, (count) ->
      factory.totalCount = count
      factory.next()

  factory.updateFilter = () ->
    for k,v of factory.filter
      if !v
        delete factory.filter[k]
    factory.count()
    
  factory.insert = () ->
    hash = md5.createHash(angular.toJson(factory.filter))
    window.socket.emit factory.datatype + ".insert", {item: factory.filter, hash: hash}
    window.socket.once factory.datatype + ".insert.status." + hash, (data) ->
      if data[0]
        factory.data.push data[1]
        factory.filter = {}   
        factory.updateFilter()
        toaster.pop "success", "Erfolg", factory.getName(data[1]) + " wurde gespeichert."   
      else
        if data[1]
          toaster.pop "error", "Fehler", data[1] 
              
  factory.update = (arrayItem) ->
    hash = md5.createHash(angular.toJson(arrayItem))
    window.socket.emit factory.datatype + ".update", {item: arrayItem, hash: hash}
    window.socket.once factory.datatype + ".update.status." + hash, (data) ->
      if data[0]
        arrayItem.changed = false        
        toaster.pop "success", "Erfolg", factory.getName(arrayItem) + " wurde gespeichert."
        $rootScope.$$phase || $rootScope.$apply()
      else
        if data[1]
          toaster.pop "error", "Fehler", data[1] 


  factory.remove = (arrayItem) ->
    hash = md5.createHash(arrayItem._id)
    window.socket.emit factory.datatype + ".remove", {itemid: arrayItem._id, hash: hash}
    window.socket.once factory.datatype + ".remove.status." + hash, (data) ->
      if data[0]
        index = factory.data.indexOf arrayItem
        factory.data.splice index,1
        toaster.pop "success", "Erfolg", factory.getName(arrayItem) + " wurde gelöscht."
        $rootScope.$$phase || $rootScope.$apply()        
      else
        if data[1]
          toaster.pop "error", "Fehler", data[1]
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
