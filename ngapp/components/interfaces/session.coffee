angular.module('interfaces')
.service "session", ($rootScope,$cookieStore,config) ->
  self = this
  activeInstitute = $cookieStore.get("activeInstitute")
  activeInstitute = "" if not activeInstitute
  activeSemester = $cookieStore.get("activeSemester")
  if not activeSemester
    config.get("semesters").then (response) ->
      if response.success and response.content
        semesters = response.content
        now = Date.now()
        semester = undefined
        for sem in semesters
          if sem.start<now and sem.end>now
            semester = sem
            break
        if not semester
          semesters = _.sortBy semesters, (sem) -> sem.start
          semester = _.last semesters
        self.setActiveSemester(response.content)
  user = $cookieStore.get("user")
  user = {} if not user
  this.setActiveInstitute = (institute) ->
    activeInstitute = {name: institute.name, image: institute.image}
    $cookieStore.put("activeInstitute", institute)
    $rootScope.$$phase || $rootScope.$apply() 
  this.getActiveInstitute = () ->
    return activeInstitute
  this.setActiveSemester = (semester) ->
    activeSemester = {name: semester.name, start: semester.start, end:semester.end}
    $cookieStore.put("activeSemester", semester)
    $rootScope.$$phase || $rootScope.$apply() 
  this.getActiveSemester= () ->
    return activeSemester
  this.setUser = (newUser) ->
    $cookieStore.put("user", newUser)
    user = newUser
    $rootScope.$$phase || $rootScope.$apply() 
  this.getUser = () ->
    return user
  return this
