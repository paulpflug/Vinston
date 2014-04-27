angular.module('socketData', []).factory "socketData", ($rootScope,$filter,md5,toaster) ->
  factory = {}
  factory.disabled = true
  factory.datatype = ""
  factory.options = {
    nameOfItem : "name"
    idOfItem : "_id"
    parentIdOfItem : "parentId"
    nameOfDatabase : ""
    showDeleted : false
    showDiffs : true
  }
  factory.data = []
  factory.unchangedData = []
  factory.history = []
  factory.historyVisible = false
  factory.historyLatestVersion = 1
  factory.filter = {}
  factory.busy = false
  factory.inconsistent = false
  factory.after = 0
  factory.totalCount = 0
  factory.socket = ""
  factory.setup = (datatype, $scope, options) ->
    factory.socket = io.connect("/"+datatype)
    $scope.$on("$destroy", () -> factory.socket.disconnect())
    factory.datatype = datatype
    for k,v of options
      factory.options[k] = v
    factory.reset()
    factory.socket.on "inserted", (data) ->
      if(factory.after >= factory.totalCount)
        factory.addLocally data
        toaster.pop "info", factory.options.nameOfDatabase + " hinzugefügt", factory.getName(data) + " wurde hinzugefügt."   
        $scope.$$phase || $scope.$apply()
    factory.socket.on "updated", (newdata) ->
      delete newdata.changed
      delete newdata["$$hashKey"]
      index = _.findIndex factory.data, (item) -> item[factory.options.idOfItem] == newdata[factory.options.idOfItem]
      if index > -1     
        olddata = factory.data[index]        
        s = factory.getName(olddata) + " wurde" 
        if newdata.deleted
          index = factory.data.indexOf olddata
          factory.removeLocally index
          toaster.pop "info", factory.options.nameOfDatabase + " entfernt", s+" entfernt." 
          $scope.$$phase || $scope.$apply()  
        else
          if factory.getName(newdata) != factory.getName(olddata)
            s += " zu "+ factory.getName(newdata)
          s+= " verändert."
          toaster.pop "info", factory.options.nameOfDatabase + " verändert", s   
          index = factory.data.indexOf olddata
          factory.data[index] = newdata
          $scope.$$phase || $scope.$apply()
      else
        toaster.pop "info", factory.options.nameOfDatabase + " verändert", factory.getName(newdata)+ " wurde verändert"
        factory.count()
    factory.socket.on "deleted", (id) ->
      index = _.findIndex factory.data, (item) -> item[factory.options.idOfItem] == id
      if index > -1     
        olddata = factory.data[index]     
        toaster.pop "info", factory.options.nameOfDatabase + " entfernt", factory.getName(olddata) + " wurde entfernt"   
        index = factory.data.indexOf olddata
        factory.removeLocally index
        $scope.$$phase || $scope.$apply()
  factory.getName = (arrayItem) ->
    if arrayItem[factory.options.nameOfItem]
      return arrayItem[factory.options.nameOfItem]
    else
      return arrayItem[factory.options.idOfItem]
  factory.reset = () ->
    factory.data = []
    factory.unchangedData = []
    factory.count()
  factory.toggleDeleted = () ->
    factory.options.showDeleted = !factory.options.showDeleted
    factory.reset()
  factory.setChanged = (arrayItem) ->
    indexold = _.findIndex factory.unchangedData, (item) -> item[factory.options.idOfItem] == arrayItem[factory.options.idOfItem]
    if indexold >-1
      indexnew = factory.data.indexOf arrayItem
      if indexold == indexnew  
        oldItem = factory.unchangedData[indexold]
        newItem = _.cloneDeep(arrayItem)
        delete newItem.changed
        delete newItem["$$hashKey"]
        diff = DeepDiff.diff(oldItem,newItem)
        arrayItem.changed = if diff then true else false
        $rootScope.$$phase || $rootScope.$apply()
      else
        factory.setInconsistent()
    

  factory.find = (cb, collection) ->
    hash = md5.createHash(angular.toJson(collection))
    factory.socket.emit "find", {collection: collection, hash: hash}
    console.log "requested " + factory.datatype
    factory.socket.once "data." + hash, (data) ->
      console.log "recieved " + factory.datatype
      cb(data)
    
  factory.count = () ->
    modifiedFilter = {}    
    for key,value of factory.filter
      if typeof value == "string" and value != ""
        modifiedFilter[key] = { $regex: value }
      if typeof value == "object" and value.length >0
        modifiedFilter[key] = value
    if not factory.options.showDeleted
      modifiedFilter.deleted = false
    collection = {find: modifiedFilter}
    hash = md5.createHash(angular.toJson(collection))
    factory.socket.emit "count", {collection: collection, hash:hash} 
    factory.socket.once "countdata." + hash, (count) ->
      factory.totalCount = count
      return if factory.busy
      factory.after = $filter("filter")(factory.data,factory.filter,"true").length
      if(factory.after< factory.totalCount)
        factory.busy = true
        factory.find((data) ->
            factory.disabled = false
            for d in data
              index = _.findIndex factory.data, (item) -> item[factory.options.idOfItem] == d[factory.options.idOfItem]
              if index > -1
                factory.busy = false
                factory.setInconsistent()
                return
              else
                factory.addLocally d
            if factory.inconsistent
              toaster.pop "success", "Inkonsistenz beseitigt", "Neu geladen - die Daten sind nun konsistent"
            factory.busy = false
            factory.after += 20
            $rootScope.$$phase || $rootScope.$apply()
        , {options : {skip:factory.after,limit:20}, find: modifiedFilter}
        )
      else
        factory.disabled = false
        $rootScope.$$phase || $rootScope.$apply()

  factory.updateFilter = () ->
    for k,v of factory.filter
      if !v
        delete factory.filter[k]
    factory.count()
    
  factory.insert = () ->
    hash = md5.createHash(angular.toJson(factory.filter))
    factory.socket.emit "insert", {item: factory.filter, hash: hash}
    factory.socket.once "insert.status." + hash, (data) ->
      if data[0]
        factory.addLocally(data[1])
        factory.filter = {}   
        factory.updateFilter()
        toaster.pop "success", "Erfolg", factory.getName(data[1]) + " wurde gespeichert."   
      else
        if data[1]
          toaster.pop "error", "Fehler", data[1] 
  factory.useOldItem = (arrayItem) ->
    arrayItem.version = factory.historyLatestVersion
    arrayItem.updated = factory.history[0].updated
    factory.update arrayItem      
  factory.update = (arrayItem, cb) ->
    hash = md5.createHash(angular.toJson(arrayItem))
    index = _.findIndex factory.unchangedData, (item) -> item[factory.options.idOfItem] == arrayItem[factory.options.idOfItem]
    if index >-1
      oldItem = factory.unchangedData[index]
      newItem = _.cloneDeep(arrayItem)
      delete newItem.changed
      delete newItem["$$hashKey"]
      changeItem = DeepDiff.diff(newItem,oldItem)
      if !cb
        cb = (data) ->
          if data[0]
            delete data[1].changed 
            factory.setLocally(index,data[1])               
            toaster.pop "success", "Erfolg", factory.getName(arrayItem) + " wurde gespeichert."
            $rootScope.$$phase || $rootScope.$apply()
          else
            if data[1]
              toaster.pop "error", "Fehler", data[1] 
      factory.socket.emit "update", {item: arrayItem, hash: hash, changeItem: changeItem}
      factory.socket.once "update.status." + hash, cb
    else
      factory.reset()
  factory.setInconsistent = () ->
    toaster.pop "error", "Inkonsistent", "Die Daten sind inkonsistent - lade neu"
    factory.inconsistent = true
    factory.reset()
  factory.unchange = (arrayItem) ->
    indexold = _.findIndex factory.unchangedData, (item) -> item[factory.options.idOfItem] == arrayItem[factory.options.idOfItem]
    if indexold >-1
      indexnew = factory.data.indexOf arrayItem
      if indexold == indexnew  
        factory.data[indexnew] = _.cloneDeep(factory.unchangedData[indexnew])
        $rootScope.$$phase || $rootScope.$apply()
      else
        factory.setInconsistent()
  factory.delete = (arrayItem) ->  
    arrayItem.deleted = true  
    factory.update arrayItem, (data) ->
      if data[0]
        toaster.pop "success", "Erfolg", factory.getName(arrayItem) + " wurde gelöscht."
        if !factory.options.showDeleted
          index = factory.data.indexOf arrayItem
          factory.removeLocally(index)
        $rootScope.$$phase || $rootScope.$apply()
      else
        arrayItem.deleted = false
        if data[1]
          toaster.pop "error", "Fehler", data[1] 
  factory.undelete = (arrayItem) ->
    arrayItem.deleted = false
    factory.update arrayItem, (data) ->
      if data[0]
        toaster.pop "success", "Erfolg", factory.getName(arrayItem) + " wurde hinzugefügt."  
        $rootScope.$$phase || $rootScope.$apply()
      else
        if data[1]
          toaster.pop "error", "Fehler", data[1]
  factory.remove = (arrayItem) ->
    hash = md5.createHash(arrayItem[factory.options.idOfItem])
    factory.socket.emit "remove", {itemid: arrayItem[factory.options.idOfItem], hash: hash}
    factory.socket.once "remove.status." + hash, (data) ->
      if data[0]
        index = factory.data.indexOf arrayItem
        factory.removeLocally(index)
        toaster.pop "success", "Erfolg", factory.getName(arrayItem) + " wurde entfernt."
        $rootScope.$$phase || $rootScope.$apply()        
      else
        if data[1]
          toaster.pop "error", "Fehler", data[1]
  factory.addLocally = (arrayItem) ->
    factory.data.push arrayItem
    factory.unchangedData.push(_.cloneDeep(arrayItem))
  factory.setLocally = (index,arrayItem) ->
    currentid = factory.data[index][factory.options.idOfItem]
    currentid2 = factory.unchangedData[index][factory.options.idOfItem]
    if arrayItem[factory.options.idOfItem] == currentid and currentid == currentid2
      factory.data[index] = _.cloneDeep(arrayItem)
      factory.unchangedData[index] = _.cloneDeep(arrayItem)
    else
      factory.setInconsistent()
  factory.removeLocally = (index) ->
    factory.data.splice index,1
    factory.unchangedData.splice index,1
  
  factory.showHistory = (arrayItem) ->
    factory.historyVisible = true
    factory.history = []
    factory.history.push arrayItem
    factory.historyLatestVersion = arrayItem.version
    find = {}
    find[factory.options.parentIdOfItem] = arrayItem[factory.options.idOfItem]
    options = { sort: { version: -1}}
    collection = {find: find, options: options}
    hash = md5.createHash(angular.toJson(collection))
    factory.socket.emit "history", {collection: collection, hash: hash}
    console.log "requested " + factory.datatype
    factory.socket.once "history." + hash, (data) ->
      console.log "recieved " + factory.datatype
      oldItem = arrayItem 
      newItem = _.cloneDeep(arrayItem)           
      for item in data
        for change in item.changes
          DeepDiff.applyChange(newItem,oldItem,change)
        delete oldItem["$$hashKey"]
        newItem.updated = item.updated
        newItem.updatedBy = item.updatedBy
        newItem.version = item.version
        factory.history.push newItem
        oldItem = newItem
        newItem = _.cloneDeep(newItem)
      $rootScope.$$phase || $rootScope.$apply()   
          

  return factory