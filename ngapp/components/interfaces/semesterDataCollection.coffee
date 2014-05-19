angular.module('interfaces')
.factory "semesterDataCollection", ($rootScope,$filter,$q,generate,clean,toaster) ->
  class semesterDataCollection
    constructor: (dataname, scope, options) ->
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
        parentIdOfItem : "parentId"
        nameOfDatabase : ""
        showDeleted : false
        showDiffs : true
      }
      angular.extend(@options,options)
      @status = ""
      @statusText = ""
      @type = ""
      @unchangedData = []
      @history = []
      @historyVisible = false
      @historyLatestVersion = 1
      @inconsistent = false
      @after = 0
      @totalCount = 0
      @socket = io.connect("/"+dataname)
      scope.$on("$destroy", () -> self.socket.disconnect())
      self.reset().finally(d.resolve)
      self.socket.on "inserted", (data) ->
        if(self.after >= self.totalCount)
          self.addLocally data
          toaster.pop "info", self.options.nameOfDatabase + " hinzugefügt", self.getName(data) + " wurde hinzugefügt."   
          $scope.$$phase || $scope.$apply()
      self.socket.on "updated", (newdata) ->
        delete newdata.changed
        delete newdata["$$hashKey"]
        index = _.findIndex self.data, (item) -> item[self.options.idOfItem] == newdata[self.options.idOfItem]
        if index > -1     
          olddata = self.data[index]        
          s = self.getName(olddata) + " wurde" 
          if newdata.deleted
            index = self.data.indexOf olddata
            self.removeLocally index
            toaster.pop "info", self.options.nameOfDatabase + " entfernt", s+" entfernt." 
            $scope.$$phase || $scope.$apply()  
          else
            if self.getName(newdata) != self.getName(olddata)
              s += " zu "+ self.getName(newdata)
            s+= " verändert."
            toaster.pop "info", self.options.nameOfDatabase + " verändert", s   
            index = self.data.indexOf olddata
            self.data[index] = newdata
            $scope.$$phase || $scope.$apply()
        else
          toaster.pop "info", self.options.nameOfDatabase + " verändert", self.getName(newdata)+ " wurde verändert"
          self.count()
      self.socket.on "deleted", (id) ->
        index = _.findIndex self.data, (item) -> item[self.options.idOfItem] == id
        if index > -1     
          olddata = self.data[index]     
          toaster.pop "info", self.options.nameOfDatabase + " entfernt", self.getName(olddata) + " wurde entfernt"   
          index = self.data.indexOf olddata
          self.removeLocally index
          $scope.$$phase || $scope.$apply()
          
    getName: (arrayItem) ->
      self = @
      if arrayItem[self.options.nameOfItem]
        return arrayItem[self.options.nameOfItem]
      else
        return arrayItem[self.options.idOfItem]

    reset: () ->
      d = $q.defer()
      self = @
      self.data = []
      self.unchangedData = []
      self.count().then(d.resolve,d.reject)
      return d.promise

    toggleDeleted: () ->
      self = @
      self.options.showDeleted = !self.options.showDeleted
      self.reset()

    setChanged: (arrayItem) ->
      self = @
      indexold = _.findIndex self.unchangedData, (item) -> item[self.options.idOfItem] == arrayItem[self.options.idOfItem]
      if indexold >-1
        indexnew = self.data.indexOf arrayItem
        if indexold == indexnew  
          oldItem = self.unchangedData[indexold]
          newItem = _.cloneDeep(arrayItem)
          delete newItem.changed
          delete newItem["$$hashKey"]
          diff = DeepDiff.diff(oldItem,newItem)
          arrayItem.changed = if diff then true else false
          $rootScope.$$phase || $rootScope.$apply()
        else
          self.setInconsistent()
      

    find: (collection) ->
      self = @
      d = $q.defer()
      token = generate.token()
      self.socket.emit "find", {content: collection, token: token}
      self.socket.once "find." + token, (response) ->
        if response
          d.resolve(response)
        else
          d.reject()
      return d.promise
    
    load: (collection) ->
      self = @
      d = $q.defer()
      if not collection
        modifiedFilter = clean.filter(self.filter)    
        if not self.options.showDeleted
          modifiedFilter.deleted = false
        collection = {
          find: modifiedFilter
        }
      self.busy = true
      self.find(collection)
      .then (response) ->
        if response.success          
          self.data = response.content
          self.unchangedData = _.cloneDeep(self.data)
        self.busy = false
        d.resolve(response)
      return d.promise

    count: () ->
      self = @
      d = $q.defer()
      modifiedFilter = clean.filter(self.filter)    
      if not self.options.showDeleted
        modifiedFilter.deleted = false
      collection = {find: modifiedFilter}
      token = generate.token()
      self.socket.emit "count", {content: collection, token:token} 
      self.socket.once "count." + token, (response) ->
        if response and response.success and response.content
          self.totalCount = response.content
          return if self.busy
          self.after = $filter("filter")(self.data,self.filter,"true").length
          if(self.after< self.totalCount)
            self.busy = true
            self.find {options : {skip:self.after,limit:20}, find: modifiedFilter}
            .then (response) ->
              if response and response.success and response.content
                self.disabled = false
                for data in response.content
                  index = _.findIndex self.data, (item) -> item[self.options.idOfItem] == data[self.options.idOfItem]
                  if index > -1
                    self.busy = false
                    self.setInconsistent()
                    return
                  else
                    self.addLocally data
                if self.inconsistent
                  toaster.pop "success", "Inkonsistenz beseitigt", "Neu geladen - die Daten sind nun konsistent"
                  self.inconsistent = false
                self.busy = false
                self.after += 20
                $rootScope.$$phase || $rootScope.$apply()
                d.resolve()        
          else
            self.disabled = false
            $rootScope.$$phase || $rootScope.$apply()
            d.resolve()
        else
          d.reject()
      return d.promise

    updateFilter: () ->
      self = @
      for k,v of self.filter
        if !v or (angular.isArray(v) and v.length == 0)
          delete self.filter[k]
      self.count()
      
    insert: (arrayItem) ->
      d = $q.defer()
      arrayItem = self.filter if not arrayItem
      self = @
      console.log "inserting..."
      token = generate.token()
      self.socket.emit "insert", {content: arrayItem, token: token}
      self.socket.once "insert." + token, (response) ->
        if response 
          if response.success and response.content
            self.addLocally(response.content)
            self.filter = {}   
            self.updateFilter()
            toaster.pop "success", "Erfolg", self.getName(response.content) + " wurde gespeichert."   
          else
            toaster.pop "error", "Fehler",""
          d.resolve(response)
        else
          d.reject()
      return d.promise
      
    useOldItem: (arrayItem) ->
      self = @
      arrayItem.version = self.historyLatestVersion
      arrayItem.updated = self.history[0].updated
      self.update arrayItem     

    update: (arrayItem,index) ->
      self = @
      d = $q.defer()
      if not index
        index = _.findIndex self.unchangedData, (item) -> item[self.options.idOfItem] == arrayItem[self.options.idOfItem]
      if index >-1
        oldItem = self.unchangedData[index]
        newItem = _.cloneDeep(arrayItem)
        delete newItem.changed
        delete newItem["$$hashKey"]
        changeItem = DeepDiff.diff(newItem,oldItem)
            
        token = generate.token()
        self.socket.emit "update", {content: arrayItem, token: token, changes: changeItem}
        self.socket.once "update." + token, (response) ->
          if response
            d.resolve(response)
          else
            d.reject()
      else
        d.reject()
        self.reset()
      return d.promise

    save: (arrayItem) ->
      self = @
      index = _.findIndex self.unchangedData, (item) -> item[self.options.idOfItem] == arrayItem[self.options.idOfItem]
      if index >-1
        self.update(arrayItem, index)
        .then (response) ->
          if response.success and response.content
            delete response.content.changed 
            self.setLocally(index,response.content)               
            toaster.pop "success", "Erfolg", self.getName(arrayItem) + " wurde gespeichert."
            $rootScope.$$phase || $rootScope.$apply()
          else
            toaster.pop "error", "Fehler" , ""

    setInconsistent: () ->
      self = @
      toaster.pop "error", "Inkonsistent", "Die Daten sind inkonsistent - lade neu"
      self.inconsistent = true
      self.reset()

    unchange: (arrayItem) ->
      self = @
      indexold = _.findIndex self.unchangedData, (item) -> item[self.options.idOfItem] == arrayItem[self.options.idOfItem]
      if indexold >-1
        indexnew = self.data.indexOf arrayItem
        if indexold == indexnew  
          self.data[indexnew] = _.cloneDeep(self.unchangedData[indexnew])
          $rootScope.$$phase || $rootScope.$apply()
        else
          self.setInconsistent()

    delete: (arrayItem) -> 
      self = @ 
      arrayItem.deleted = true  
      self.update arrayItem
      .then (response) ->
        if response.success
          toaster.pop "success", "Erfolg", self.getName(arrayItem) + " wurde gelöscht."
          if !self.options.showDeleted
            index = self.data.indexOf arrayItem
            self.removeLocally(index)
          $rootScope.$$phase || $rootScope.$apply()
        else
          arrayItem.deleted = false
          toaster.pop "error", "Fehler", ""

    undelete: (arrayItem) ->
      self = @
      arrayItem.deleted = false
      self.update arrayItem
      .then (data) ->
        if response.success
          toaster.pop "success", "Erfolg", self.getName(arrayItem) + " wurde hinzugefügt."  
          $rootScope.$$phase || $rootScope.$apply()
        else
          arrayItem.deleted = true
          toaster.pop "error", "Fehler", ""

    remove: (arrayItem) ->
      self = @
      token = generate.token()
      self.socket.emit "remove", {content:{id: arrayItem[self.options.idOfItem]}, token: token}
      self.socket.once "remove." + token, (response) ->
        if response and response.success
          index = self.data.indexOf arrayItem
          self.removeLocally(index)
          toaster.pop "success", "Erfolg", self.getName(arrayItem) + " wurde entfernt."
          $rootScope.$$phase || $rootScope.$apply()        
        else
          toaster.pop "error", "Fehler", ""

    addLocally: (arrayItem) ->
      self = @
      self.data.push arrayItem
      self.unchangedData.push(_.cloneDeep(arrayItem))

    setLocally: (index,arrayItem) ->
      self = @
      currentid = self.data[index][self.options.idOfItem]
      currentid2 = self.unchangedData[index][self.options.idOfItem]
      if arrayItem[self.options.idOfItem] == currentid and currentid == currentid2
        self.data[index] = _.cloneDeep(arrayItem)
        self.unchangedData[index] = _.cloneDeep(arrayItem)
      else
        self.setInconsistent()

    removeLocally: (index) ->
      self = @
      self.data.splice index,1
      self.unchangedData.splice index,1
    
    showHistory: (arrayItem) ->
      self = @
      self.historyVisible = true
      self.history = []
      self.history.push arrayItem
      self.historyLatestVersion = arrayItem.version
      find = {}
      find[self.options.parentIdOfItem] = arrayItem[self.options.idOfItem]
      options = { sort: { version: -1}}
      collection = {find: find, options: options}
      token = generate.token()
      self.socket.emit "history", {content: collection, token: token}
      self.socket.once "history." + token, (response) ->
        if response and response.success
          oldItem = arrayItem 
          newItem = _.cloneDeep(arrayItem)           
          for item in response.content
            for change in item.changes
              DeepDiff.applyChange(newItem,oldItem,change)
            delete oldItem["$$hashKey"]
            newItem.updated = item.updated
            newItem.updatedBy = item.updatedBy
            newItem.version = item.version
            self.history.push newItem
            oldItem = newItem
            newItem = _.cloneDeep(newItem)
          $rootScope.$$phase || $rootScope.$apply()   