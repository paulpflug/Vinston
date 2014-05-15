mod = angular.module('globals')

mod.service "clean", () ->
  keys = ["changed","busy","status","statusText","$$hashKey"]
  deleteKeys = (obj) ->
    for key in keys
      delete obj[key]
    return obj
  return (arg) ->
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

mod.factory "generate", () ->
  new class generate
    constructor: () ->
      @ids = []

    token: () ->
      number = 0
      while number == 0 or number == 1
        number = Math.random()
      return number.toString(36).substr(2)

    id: (length) ->
      length = 6 if not length
      index = 0
      while index > -1
        id = this.token().substr(0,length)
        index = @ids.indexOf(id)
      @ids.push(id)
      return id








            

