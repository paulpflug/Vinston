angular.module('interfaces')
.factory "semesterDataCollection", ($rootScope,$filter,$q,semesterData,generate,clean,toaster) ->
  class semesterDataCollection extends semesterData
    constructor: (options) ->
      self = @
      defaultOptions = {
        parentIdOfItem : "parentId"
        showDiffs : true
      }
      options = angular.extend(defaultOptions,options)
      options.singleItem = false
      super(options)
      @history = []
      @historyVisible = false
      @historyLatestVersion = 1
      @after = 0
      @totalCount = 0
      

    reload: () ->
      d = $q.defer()
      self = @
      self.data = []
      self.unchangedData = []
      self.count().then(d.resolve,d.reject)
      return d.promise

    count: () ->
      self = @
      d = $q.defer()
      token = generate.token()
      query = self.options.query
      return if self.busy
      self.busy = true
      self.socket.emit "count", {content: query, token:token} 
      self.socket.once "count." + token, (response) ->
        if response and response.success and response.content
          self.totalCount = response.content
          self.after = $filter("filter")(self.data,self.filter,"true").length
          if(self.after < self.totalCount)
            query.options = {skip:self.after,limit:20}
            self.find query
            .then (response) ->
              if response and response.success and response.content
                self.disabled = false
                for data in response.content
                  index = _.findIndex self.data, (item) -> item[self.options.idOfItem] == data[self.options.idOfItem]
                  if index > -1
                    console.log "count"
                    console.log self.data
                    self.setInconsistent()
                    return
                  else
                    self.addLocally data
                if self.inconsistent
                  toaster.pop "success", "Inkonsistenz beseitigt", "Neu geladen - die Daten sind nun konsistent"
                  self.inconsistent = false
                self.after += 20
                $rootScope.$$phase || $rootScope.$apply()
                d.resolve()        
          else
            self.disabled = false
            
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
      self = @
      d = $q.defer()
      arrayItem = self.filter if not arrayItem
      super(arrayItem)
      .then (response) ->
        if response.success and response.content
          self.filter = {}   
          self.updateFilter()
          d.resolve(response)
        else
          d.reject()
      return d.promise
      
    useOldItem: (arrayItem) ->
      self = @
      arrayItem.version = self.historyLatestVersion
      arrayItem.updated = self.history[0].updated
      self.update arrayItem     

    
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