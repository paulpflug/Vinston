mod = angular.module('globals')

mod.service "clean", () ->
  keys = ["changed","busy","status","statusText","$$hashKey"]
  deleteKeys = (obj) ->
    for key in keys
      delete obj[key]
    for k,v of obj
      if angular.isArray(v)
        for obj in v
          deleteKeys(obj)
    return obj
  new class clean
    constructor: () ->

    deepClone: (arg) ->
      obj = _.deepClone(arg)
      return deleteKeys(obj)
    object: (arg) ->
      if angular.isArray(arg)
        newArg = []
        for obj in arg
          if angular.isObject(obj)
            newArg.push(deleteKeys(obj))
        arg = newArg
      else
        if angular.isObject(arg)
          arg = deleteKeys(arg)
      return arg
    filter: (arg) ->
      modifiedFilter = {}    
      for key,value of arg
        if angular.isString(+value) and value != ""
          modifiedFilter[key] = { $regex: value }
        else
          if not (angular.isUndefined(value) or value == null)
            modifiedFilter[key] = value
      return modifiedFilter

mod.factory "generate", () ->
  ids = []
  lastToken = [false,false,false]
  index = 0
  new class generate

    token: (length) ->
      length = 3 if not length
      length = 15 if length>15
      length = 1 if length<1
      loop 
        loop
          number = Math.random()
          break unless number == 0 or number == 1
        token = number.toString(36).substr(2)
        break unless lastToken.indexOf(token) > -1
      lastToken[index] = token
      index = (index+1) % 3
      return token.substr(0,length)

    id: (length) ->
      length = 6 if not length
      index = 0
      while index > -1
        id = this.token(length)
        index = ids.indexOf(id)
      ids.push(id)
      return id

    abbreviation: (str,length) ->
      length = 3 if not length
      return str if length > str.length
      regexes = [/\s/,/[aeouäöü]/,/[a-z]/,/[AEOUÄÖÜ]/,/[A-Z]/]
      chars = str.split("")
      words = []
      charcounts = {1:0}
      i = 1
      for c in chars
        if c.search(regexes[0]) > -1
          i++
          words.push 0
          charcounts[i] = 0
        else
          words.push i
          charcounts[i]++
      i = 0
      while i < regexes.length
        j = chars.length
        while j > 0
          j--
          if chars[j].search(regexes[i]) > -1
            if words[j] == 0 or charcounts[words[j]] > 1
              charcounts[words[j]]--
              chars.splice j,1
              words.splice j,1
              if chars.length == length
                break
        if chars.length == length
          break
        i++
      return chars.join("")








            

