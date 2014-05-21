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
        if angular.isString(value) and value != ""
          modifiedFilter[key] = { $regex: value }
        if typeof value == "object" and value.length >0
          modifiedFilter[key] = value
      return modifiedFilter

mod.factory "generate", () ->
  new class generate
    constructor: () ->
      @ids = []

    token: (length) ->
      length = 3 if not length
      length = 15 if length>15
      length = 1 if length<1
      number = 0
      while number == 0 or number == 1
        number = Math.random()
      token = number.toString(36).substr(2)
      return token.substr(0,length)

    id: (length) ->
      length = 6 if not length
      index = 0
      while index > -1
        id = this.token(length)
        index = @ids.indexOf(id)
      @ids.push(id)
      return id








            

