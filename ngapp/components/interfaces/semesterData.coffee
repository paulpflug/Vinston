angular.module('interfaces')
.factory "semesterData", ($rootScope,$filter,$q,$timeout,generate,clean,toaster) ->
  class semesterData
    constructor: (options) ->
      d = $q.defer()
      self = @
      @loaded = d.promise
      @busy = false
      @changed = false
      @options = {
        nameOfItem : "name"
        idOfItem : "_id"
        nameOfDatabase : ""
        showDeleted : false
        singleItem: false
        filterBy: {}
        orderBy: undefined
        query: {}
        scope: $rootScope.$new()
        connection:""
        connectTimeout: 1000
      }
      angular.extend(@options,options)
      @filter = {}
      @inconsistent = false
      @status = ""
      @statusText = ""
      @type = ""
      self.options.scope.$watch self.options.connection,(newVal,oldVal) ->
        if newVal != oldVal 
          angular.bind(self,self.connect)()
          .then angular.bind(self,self.reload)
      self.options.scope.$on "$destroy", () -> self.channel.disconnect()
      self.updateQuery(self.options.query)
      for k,v of self.options.filterBy
        self.options.scope.$watch v, (newVal,oldVal) ->
          if newVal != oldVal 
            angular.bind(self,self.updateQuery)(self.options.query)
            angular.bind(self,self.reload)()   
      if self.options.orderBy
        self.options.scope.$watch self.options.orderBy, ((newVal,oldVal) -> 
          if newVal != oldVal 
            angular.bind(self,self.updateQuery)(self.options.query)
            angular.bind(self,self.sort)()),true        
      self.connect()
      .then angular.bind(self,self.reload)
      .finally d.resolve

    updateQuery: (query,noFilter,noOrder) ->
      self = @
      query = {} if not query
      if not query.find
        query.find = _.cloneDeep(self.filter)     
      if not self.options.showDeleted
        query.find.deleted = false
      if not noFilter
        for k,v of self.options.filterBy
          query.find[k] = self.options.scope.$eval(v)
      if not noOrder and self.options.orderBy
        query.options = {} if not query.options
        arr = self.options.scope.$eval(self.options.orderBy)
        if arr and angular.isArray(arr)
          query.options.sort = arr.join(" ")
      query.find = clean.filter(query.find)  
      return query
    sortArray: (array) ->
      self = @
      prop = []
      order = []
      for s in self.options.scope.$eval(self.options.orderBy)
        if s.charAt(0) == "-"
          prop.push s.slice(1)
          order.push -1
        else
          prop.push s
          order.push 1
      return array.sort (a,b) ->
        result = 0
        for i in _.range(prop.length)
          p1 = a[prop[i]]
          p2 = b[prop[i]]
          if angular.isString(p1)
            result = p1.localeCompare(p2)
          else
            if p1 < p2
              result = -1
            else if p1 > p2
              result = 1
          if result != 0
            result = result*order[i]
            break
        return result
    sort: () ->
      self = @
      d = $q.defer()
      if not self.options.singleItem  
        self.unchangedData = self.sortArray(self.data)      
        self.data = _.cloneDeep(self.unchangedData) 
      d.resolve()
      return d.promise
    connect: () ->
      d = $q.defer()
      self = @ 
      if self.channel
        self.channel.disconnect()
      timeout = $timeout (() ->
        self.channel.disconnect()
        d.reject()), self.options.connectTimeout
      self.channel = io "/"+self.options.scope.$eval(self.options.connection)
      self.channel.on "isReal", () -> 
        $timeout.cancel timeout
        d.resolve()
      self.channel.on "inserted", (id) ->
        if(self.after >= self.totalCount)
          query = {find:{}}
          query.find[self.options.idOfItem] = id
          self.find(query).then (response) ->
            if response and response.success
              self.addLocally(response.content)
              toaster.pop "info", self.options.nameOfDatabase + " hinzugefügt", self.getName(response.content) + " wurde hinzugefügt."   
      self.channel.on "updated", (id) ->
        index = _.findIndex self.data, (item) -> item[self.options.idOfItem] == id
        query = {find:{}}
        query.find[self.options.idOfItem] = id
        if index > -1   
          self.find(query).then (response) ->
            if response and response.success
              newdata = response.content
              olddata = self.data[index]        
              s = self.getName(olddata) + " wurde" 
              if newdata.deleted
                if !self.options.showDeleted
                  index = self.data.indexOf olddata
                  self.removeLocally index
                toaster.pop "info", self.options.nameOfDatabase + " entfernt", s+" entfernt."   
              else
                if self.getName(newdata) != self.getName(olddata)
                  s += " zu "+ self.getName(newdata)
                s+= " verändert."
                toaster.pop "info", self.options.nameOfDatabase + " verändert", s   
                index = self.data.indexOf olddata
                self.data[index] = newdata
        else
          toaster.pop "info", self.options.nameOfDatabase + " verändert", self.getName(newdata)+ " wurde verändert"
          self.count()
      self.channel.on "deleted", (id) ->
        index = _.findIndex self.data, (item) -> item[self.options.idOfItem] == id
        if index > -1     
          olddata = self.data[index]     
          toaster.pop "info", self.options.nameOfDatabase + " entfernt", self.getName(olddata) + " wurde entfernt"   
          index = self.data.indexOf olddata
          self.removeLocally index
      return d.promise


    getName: (item) ->
      self = @
      if item[self.options.nameOfItem]
        return item[self.options.nameOfItem]
      else
        return item[self.options.idOfItem]

    find: (query) ->
      self = @
      d = $q.defer()
      token = generate.token()
      self.busy = true
      self.channel.emit "find", {content: self.updateQuery(query), token: token}
      self.channel.once "find." + token, (response) ->
        if response
          d.resolve(response)
        else
          d.reject()
        self.busy = false
      return d.promise

    reload: () ->
      return if busy
      busy = true
      console.log "reloading .."
      d = $q.defer()
      self = @ if not self
      if @options.singleItem
        self.data = {}
        self.unchangedData = {}
      else
        self.data = []
        self.unchangedData = []
      self.find(self.options.query).then(
        ((response) ->
          if response.success and response.content  
            for item in response.content      
              self.addLocally(item)
            if self.inconsistent
              toaster.pop "success", "Inkonsistenz beseitigt", "Neu geladen - die Daten sind nun konsistent"
              self.inconsistent = false
          d.resolve())
        ,d.reject)
      .finally () -> busy = false
      return d.promise
    filterIsEmpty: () ->
      self = @
      return Object.keys(self.filter).length == 0
    insert: (item) ->
      d = $q.defer()
      self = @
      token = generate.token()
      self.channel.emit "insert", {content: item, token: token}
      self.channel.once "insert." + token, (response) ->
        if response 
          if response.success and response.content       
            self.addLocally(response.content)
            toaster.pop "success", "Erfolg", self.getName(response.content) + " wurde gespeichert."   
          else
            toaster.pop "error", "Fehler",""
          d.resolve(response)
        else
          d.reject()
      return d.promise

    getChanges: (arrayItem) ->
      self = @
      if self.options.singleItem
        oldItem = self.unchangedData
        newItem = _.cloneDeep(arrayItem)
      else
        indexold = _.findIndex self.unchangedData, (item) -> item[self.options.idOfItem] == arrayItem[self.options.idOfItem]
        if indexold >-1
          indexnew = self.data.indexOf arrayItem
          if indexold == indexnew  
            oldItem = self.unchangedData[indexold]
            newItem = _.cloneDeep(arrayItem)
          else
            self.setInconsistent()
            return false
        else
          return false
      if newItem
        delete newItem.changed
        delete newItem["$$hashKey"]
      return DeepDiff.diff(oldItem,newItem)

    setChanged: (arrayItem) ->
      self = @
      diff = self.getChanges(arrayItem)
      arrayItem.changed = if diff then true else false

                  
    unchange: (arrayItem) ->
      self = @
      if self.options.singleItem
        self.data = _.cloneDeep(self.unchangedData)
      else
        indexold = _.findIndex self.unchangedData, (item) -> item[self.options.idOfItem] == arrayItem[self.options.idOfItem]
        if indexold >-1
          indexnew = self.data.indexOf arrayItem
          if indexold == indexnew  
            self.data[indexnew] = _.cloneDeep(self.unchangedData[indexnew])
            $rootScope.$$phase || $rootScope.$apply()
          else
            self.setInconsistent()

    update: (arrayItem) ->
      self = @
      d = $q.defer()
      if not arrayItem
        arrayItem = self.data
      diff = self.getChanges(arrayItem)
      if diff
        token = generate.token()
        self.channel.emit "update", {content: arrayItem, token: token, changes: diff}
        self.channel.once "update." + token, (response) ->
          if response
            d.resolve(response)
          else
            d.reject()
      else
        d.reject()
        self.reload()
      return d.promise

    save: (arrayItem) ->
      self = @
      if not arrayItem
        arrayItem = self.data
      console.log "saving.."
      self.update(arrayItem)
      .then (response) ->
        if response.success and response.content
          delete response.content.changed 
          self.setLocally(response.content)
            
          toaster.pop "success", "Erfolg", self.getName(arrayItem) + " wurde gespeichert."

        else
          toaster.pop "error", "Fehler" , ""


    delete: (item) -> 
      self = @ 
      item.deleted = true  
      self.update item
      .then (response) ->
        if response.success
          toaster.pop "success", "Erfolg", self.getName(item) + " wurde gelöscht."
          if !self.options.showDeleted
            index = self.data.indexOf item
            self.removeLocally(index)

        else
          item.deleted = false
          toaster.pop "error", "Fehler", ""

    undelete: (item) ->
      self = @
      item.deleted = false
      self.update item
      .then (data) ->
        if response.success
          toaster.pop "success", "Erfolg", self.getName(item) + " wurde hinzugefügt."  
        else
          item.deleted = true
          toaster.pop "error", "Fehler", ""

    remove: (item) ->
      self = @
      token = generate.token()
      self.channel.emit "remove", {content:{id: item[self.options.idOfItem]}, token: token}
      self.channel.once "remove." + token, (response) ->
        if response and response.success
          if self.options.singleItem
            self.setLocally({})
          else
            index = self.data.indexOf item
            self.removeLocally(index)
          toaster.pop "success", "Erfolg", self.getName(item) + " wurde entfernt."      
        else
          toaster.pop "error", "Fehler", ""

    setInconsistent: () ->
      self = @
      console.log "inconsistency"
      toaster.pop "error", "Inkonsistent", "Die Daten sind inkonsistent - lade neu"
      self.inconsistent = true
      self.reload()

    getIndex: (arrayItem) ->
      self = @
      id = arrayItem[self.options.idOfItem]
      unchangedIndex = _.findIndex self.unchangedData, (item) -> item[self.options.idOfItem] == id
      index = _.findIndex self.data, (item) -> item[self.options.idOfItem] == id
      if unchangedIndex != index
        self.setInconsistent()
      return index

    addLocally: (arrayItem,noSort) ->
      self = @
      index = self.getIndex(arrayItem)
      if index > -1
        self.setLocally arrayItem,index
      else
        if self.options.singleItem
          self.data = arrayItem
          self.unchangedData = _.cloneDeep(arrayItem)
        else
          self.data.push arrayItem
          self.unchangedData.push(_.cloneDeep(arrayItem))
          if self.options.orderBy and not noSort
            self.sort()
        $rootScope.$$phase || $rootScope.$apply()

    setLocally: (arrayItem,index) ->
      self = @
      if self.options.singleItem
        self.data = arrayItem
        self.unchangedData = _.cloneDeep(arrayItem)
      else
        if not index
          index = self.getIndex(arrayItem)
        if index > -1
          self.data[index] = arrayItem
          self.unchangedData[index] = _.cloneDeep(arrayItem)
        else
          self.setInconsistent()
      $rootScope.$$phase || $rootScope.$apply()


    removeLocally: (index) ->
      self = @
      if self.options.singleItem
        self.data = {}
        self.unchangedData = {}
      else
        self.data.splice index,1
        self.unchangedData.splice index,1
      $rootScope.$$phase || $rootScope.$apply()