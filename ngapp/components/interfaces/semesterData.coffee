angular.module('interfaces')
.factory "semesterData", ($rootScope,$filter,$q,generate,clean,toaster) ->
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
        query: {}
        scope: $rootScope.$new()
        connection:""
      }
      angular.extend(@options,options)
      @inconsistent = false
      @status = ""
      @statusText = ""
      @type = ""
      self.connect()
      self.options.scope.$watch(self.options.connection,() -> self.connect(self))
      self.options.scope.$on("$destroy", () -> self.socket.disconnect())
      self.updateQuery(self.options.query)
      for k,v in self.options.filterBy
        self.options.scope.$watch(v,(() -> self.updateQuery(self.options.query, self)),true)
      self.reload().finally(d.resolve)

    updateQuery: (query,self) ->
      self = @ if not self
      query = {} if not query
      query.find = {} if not query.find
      query.find = clean.filter(query.find)    
      if not self.options.showDeleted
        query.find.deleted = false
      for k,v in self.options.filterBy
        self.options.query.find[k] = self.options.scope.$eval(v)
      return query

    connect: (self) ->
      self = @ if not self
      if self.socket
        self.socket.disconnect()
      self.socket = io.connect("/"+self.options.scope.$eval(self.options.connection))    
      self.socket.on "inserted", (id) ->
        if(self.after >= self.totalCount)
          query = {find:{}}
          query.find[self.options.idOfItem] = id
          self.find(query).then (response) ->
            if response and response.success
              self.addLocally(response.content)
              toaster.pop "info", self.options.nameOfDatabase + " hinzugefügt", self.getName(response.content) + " wurde hinzugefügt."   
      self.socket.on "updated", (id) ->
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
      self.socket.on "deleted", (id) ->
        index = _.findIndex self.data, (item) -> item[self.options.idOfItem] == id
        if index > -1     
          olddata = self.data[index]     
          toaster.pop "info", self.options.nameOfDatabase + " entfernt", self.getName(olddata) + " wurde entfernt"   
          index = self.data.indexOf olddata
          self.removeLocally index


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
      self.socket.emit "find", {content: self.updateQuery(query), token: token}
      self.socket.once "find." + token, (response) ->
        if response
          d.resolve(response)
        else
          d.reject()
        self.busy = false
      return d.promise

    reload: () ->
      console.log "reloading .."
      d = $q.defer()
      self = @
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
      return d.promise
      
    insert: (item) ->
      d = $q.defer()
      self = @
      token = generate.token()
      self.socket.emit "insert", {content: item, token: token}
      self.socket.once "insert." + token, (response) ->
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
        self.socket.emit "update", {content: arrayItem, token: token, changes: diff}
        self.socket.once "update." + token, (response) ->
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
      self.socket.emit "remove", {content:{id: item[self.options.idOfItem]}, token: token}
      self.socket.once "remove." + token, (response) ->
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
      toaster.pop "error", "Inkonsistent", "Die Daten sind inkonsistent - lade neu"
      self.inconsistent = true
      self.reload()

    addLocally: (arrayItem) ->
      self = @
      if self.options.singleItem
        self.data = arrayItem
        self.unchangedData = _.cloneDeep(arrayItem)
      else
        self.data.push arrayItem
        self.unchangedData.push(_.cloneDeep(arrayItem))
      $rootScope.$$phase || $rootScope.$apply()

    setLocally: (arrayItem,index) ->
      self = @
      if self.options.singleItem
        self.data = arrayItem
        self.unchangedData = _.cloneDeep(arrayItem)
      else
        if index
          currentid = self.data[index][self.options.idOfItem]
          currentid2 = self.unchangedData[index][self.options.idOfItem]
          if arrayItem[self.options.idOfItem] == currentid and currentid == currentid2
            self.data[index] = arrayItem
            self.unchangedData[index] = _.cloneDeep(arrayItem)
          else
            self.setInconsistent()
        else
          indexold = _.findIndex self.unchangedData, (item) -> item[self.options.idOfItem] == arrayItem[self.options.idOfItem]
          if indexold >-1
            indexnew = self.data.indexOf arrayItem
            if indexold == indexnew  
              self.unchangedData[indexold] = arrayItem
              self.data[indexnew] = _.cloneDeep(arrayItem)
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