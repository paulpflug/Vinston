angular.module('configData', []).factory "configData", ($rootScope,$filter,$q,clean,config,generate,toaster) ->
  d = $q.defer()
  factory = {}
  factory.busy = false
  factory.changed = false
  factory.loaded = d.promise
  factory.dataname = ""
  factory.data = []
  factory.filter = {}
  factory.options = {
    nameOfItem : "name"
    idOfItem : "_id"
    nameOfDatabase : ""
  }
  factory.status = ""
  factory.statusText = ""
  factory.type = ""
  factory.unchangedData = []
  
  factory.setup = (dataname,scope,options) ->
    for k,v of options
      factory.options[k] = v
    factory.dataname = dataname
    $q.all([config.get(dataname),config.getType(dataname)])
    .then (results) ->
      if results.length == 2 and results[0].success and results[1].success
        factory.data = results[0].content
        factory.type = results[1].content
        if factory.type == "objects" and factory.data
          for item in factory.data
            item[factory.options.idOfItem] = generate.id()
          factory.unchangedData = _.cloneDeep(factory.data)
    .finally () -> 
      d.resolve()
      $rootScope.$$phase || $rootScope.$apply()
    cbindex = config.addUpdatecb () ->
      config.get(dataname)
      .then (response) ->
        if response.success
          factory.unchangedData = response.content
          if factory.type == "objects"
            for item in factory.unchangedData
              item[factory.options.idOfItem] = generate.id()
            for item in factory.data
              if item.changed
                toaster.pop("error","Änderung",factory.options.nameOfDatabase + " geändert")
                break
            factory.data = _.cloneDeep(factory.unchangedData)
          else            
            if !factory.changed
              factory.data = _.cloneDeep(factory.unchangedData)
            else
              toaster.pop("info","Änderung",factory.options.nameOfDatabase + " geändert")

            
    scope.$on "$destroy", () -> 
      config.removeUpdatecb cbindex
    return factory

  factory.save = (obj) ->
    d = $q.defer()
    factory.busy = true
    if factory.type == "objects" and obj
      obj.busy = true
    $rootScope.$$phase || $rootScope.$apply()
    if factory.type == "objects" and obj
      indexold = _.findIndex factory.unchangedData, (item) -> item[factory.options.idOfItem] == obj[factory.options.idOfItem]
      objold = factory.unchangedData[indexold]
      factory.unchangedData[indexold] = clean(_.cloneDeep(obj))
      data = factory.unchangedData
    else
      data = factory.data
    config.set(factory.dataname, data)
    .then (response) ->
      d.resolve(response.success)
      if response.success 
        if(factory.type == "objects" and obj)
          obj.changed = false
        else
          factory.unchangedData = _.cloneDeep(factory.data)
      if !response.success and factory.type == "objects" and obj
        factory.unchangedData[indexold] = objold
    .finally () ->
      factory.busy = false
      if factory.type == "objects" and obj
        obj.busy = false
      $rootScope.$$phase || $rootScope.$apply()
    return d.promise

  factory.delete = (obj) ->
    if factory.type == "objects" and obj
      index = factory.data.indexOf obj
      factory.data.splice(index,1)
      factory.save().then (success) ->
        if not success
          factory.data.splice(index,0,obj)


  factory.unchange = (obj) ->
    if factory.type == "objects" and obj
      indexold = _.findIndex factory.unchangedData, (item) -> item[factory.options.idOfItem] == obj[factory.options.idOfItem]
      if indexold >-1
        indexnew = factory.data.indexOf obj
        if indexold == indexnew  
          factory.data[indexnew] = _.cloneDeep(factory.unchangedData[indexnew]) 
    else
      factory.data = _.cloneDeep(factory.unchangedData)
    $rootScope.$$phase || $rootScope.$apply()

  factory.setChanged = (obj) ->
    oldItem = factory.unchangedData
    newItem = factory.data
    if factory.type == "objects" and obj
      indexold = _.findIndex factory.unchangedData, (item) -> item[factory.options.idOfItem] == obj[factory.options.idOfItem]
      if indexold >-1
        indexnew = factory.data.indexOf obj
        if indexold == indexnew  
          oldItem = factory.unchangedData[indexold]
          newItem = clean(_.cloneDeep(obj))
          diff = DeepDiff.diff(oldItem,newItem)
          obj.changed = if diff then true else false
          $rootScope.$$phase || $rootScope.$apply()
    else
      diff = DeepDiff.diff(factory.unchangedData,factory.data)
      factory.changed = if diff then true else false
    
  factory.insert = (obj) ->
    if factory.type == "objects"
      if not obj
        wasFilter = true
        obj = _.cloneDeep(factory.filter)
        obj[factory.options.idOfItem] = generate.id()
      factory.data.push (obj)
      factory.save().then (success) ->
        if success 
          factory.unchangedData.push clean(_.cloneDeep(obj))
          if wasFilter
            factory.filter = {}
        if not success
          index = factory.data.indexOf(obj)
          factory.data.splice(index,1)

  factory.test = (obj) ->
    factory.setChanged(obj)
    config.test(factory.dataname, factory.data) 
    .then (response) ->
      statusText = response.content
      if response.success
        status = "success"
      else
        status = "danger"
      if factory.type == "objects" and obj
        obj.status = status
        obj.statusText = statusText
      else
        factory.status = status
        factory.statusText = statusText
  return factory