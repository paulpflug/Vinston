angular.module('interfaces')
.factory "configData", ($rootScope,$filter,$q,clean,config,generate,toaster) ->
  class configData
    constructor:(dataname,scope,options) ->
      d = $q.defer()
      self = @
      @loaded = d.promise
      @busy = false
      @changed = false
      @dataname = dataname
      @data = []
      @filter = {}
      @options = {
        nameOfItem : "name"
        idOfItem : "_id"
        nameOfDatabase : ""
      }
      angular.extend(@options,options)
      @status = ""
      @statusText = ""
      @type = ""
      @unchangedData = []
      $q.all([config.get(self.dataname),config.getType(self.dataname)])
      .then (results) ->
        if results.length == 2 and results[0].success and results[1].success
          self.type = results[1].content
          if results[0].content
            self.data = results[0].content
            if self.type == "objects" and self.data
              for item in self.data
                item[self.options.idOfItem] = generate.id()
              self.unchangedData = _.cloneDeep(self.data)
      .finally () -> 
        d.resolve()
        $rootScope.$$phase || $rootScope.$apply()
      cbindex = config.addUpdatecb () ->
        config.get(dataname)
        .then (response) ->
          if response.success
            self.unchangedData = response.content
            if self.type == "objects"
              for item in self.unchangedData
                item[self.options.idOfItem] = generate.id()
              for item in self.data
                if item.changed
                  toaster.pop("error","Änderung",self.options.nameOfDatabase + " geändert")
                  break
              self.data = _.cloneDeep(self.unchangedData)
            else            
              if !self.changed
                self.data = _.cloneDeep(self.unchangedData)
              else
                toaster.pop("info","Änderung",self.options.nameOfDatabase + " geändert")
      scope.$on "$destroy", () -> 
        config.removeUpdatecb cbindex

    reload: () ->
      d = $q.defer()
      self = @
      config.get(self.dataname)
      .then (response) ->
        if response.success and response.content
          self.data = results[0].content
          if self.type == "objects" and self.data
            for item in self.data
              item[self.options.idOfItem] = generate.id()
            self.unchangedData = _.cloneDeep(self.data)
      .finally () -> 
        d.resolve()
        $rootScope.$$phase || $rootScope.$apply()
      return d.promise
    save: (obj) ->
      d = $q.defer()
      self = @
      self.busy = true
      if self.type == "objects" and obj
        obj.busy = true
      $rootScope.$$phase || $rootScope.$apply()
      if self.type == "objects" and obj
        indexold = _.findIndex self.unchangedData, (item) -> item[self.options.idOfItem] == obj[self.options.idOfItem]
        objold = self.unchangedData[indexold]
        self.unchangedData[indexold] = clean.object(_.cloneDeep(obj))
        data = _.cloneDeep(self.unchangedData)
      else
        data = _.cloneDeep(self.data)
      if self.type == "objects"
        for tmp in data
          delete tmp[self.options.idOfItem]
      config.set(self.dataname, data)
      .then (response) ->
        d.resolve(response.success)
        if response.success 
          if(self.type == "objects" and obj)
            obj.changed = false
          else
            self.unchangedData = _.cloneDeep(self.data)
        if !response.success and self.type == "objects" and obj
          self.unchangedData[indexold] = objold
      .finally () ->
        self.busy = false
        if self.type == "objects" and obj
          obj.busy = false
        $rootScope.$$phase || $rootScope.$apply()
      return d.promise

    delete: (obj) ->
      self = @
      if self.type == "objects" and obj
        index = self.data.indexOf obj
        self.data.splice(index,1)
        self.save().then (success) ->
          if not success
            self.data.splice(index,0,obj)


    unchange: (obj) ->
      self = @
      if self.type == "objects" and obj
        indexold = _.findIndex self.unchangedData, (item) -> item[self.options.idOfItem] == obj[self.options.idOfItem]
        if indexold >-1
          indexnew = self.data.indexOf obj
          if indexold == indexnew  
            self.data[indexnew] = _.cloneDeep(self.unchangedData[indexnew]) 
      else
        self.data = _.cloneDeep(self.unchangedData)
      $rootScope.$$phase || $rootScope.$apply()

    setChanged: (obj) ->
      self = @
      oldItem = self.unchangedData
      newItem = self.data
      if self.type == "objects" and obj
        indexold = _.findIndex self.unchangedData, (item) -> item[self.options.idOfItem] == obj[self.options.idOfItem]
        if indexold >-1
          indexnew = self.data.indexOf obj
          if indexold == indexnew  
            oldItem = self.unchangedData[indexold]
            newItem = clean.object(_.cloneDeep(obj))
            diff = DeepDiff.diff(oldItem,newItem)
            obj.changed = if diff then true else false
            $rootScope.$$phase || $rootScope.$apply()
      else
        diff = DeepDiff.diff(self.unchangedData,self.data)
        self.changed = if diff then true else false
      
    insert: (obj) ->
      self = @
      if self.type == "objects"
        if not obj
          wasFilter = true
          obj = _.cloneDeep(self.filter)
          obj[self.options.idOfItem] = generate.id()
        self.data.push (obj)
        self.save().then (success) ->
          if success 
            self.unchangedData.push clean.object(_.cloneDeep(obj))
            if wasFilter
              self.filter = {}
          if not success
            index = self.data.indexOf(obj)
            self.data.splice(index,1)

    test: (obj) ->
      self = @
      setChanged(obj)
      config.test(self.dataname, self.data) 
      .then (response) ->
        statusText = response.content
        if response.success
          status = "success"
        else
          status = "danger"
        if self.type == "objects" and obj
          obj.status = status
          obj.statusText = statusText
        else
          self.status = status
          self.statusText = statusText
