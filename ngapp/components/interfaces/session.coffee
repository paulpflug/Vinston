angular.module('interfaces')
.service "session", ($rootScope,$cookieStore,$q,config) ->
  deferred = $q.defer()
  self = this
  self.loaded = deferred.promise
  activeInstitute = $cookieStore.get("activeInstitute")
  activeSemester = $cookieStore.get("activeSemester")
  user = $cookieStore.get("user")
  loadInstitute = () ->
    if not activeInstitute
      activeInstitute = "" 
    d = $q.defer()
    d.resolve()
    return d.promise
  loadSemester = () ->
    d = $q.defer()
    if activeSemester
      d.resolve()
    else
      config.get("semesters").then (response) ->
        if response.success 
          if response.content
            semesters = response.content
            now = Date.now()
            semester = undefined
            for sem in semesters
              if new Date(sem.start).getTime()<now and new Date(sem.end).getTime()>now
                semester = sem
                break
            if not semester
              semesters = _.sortBy semesters, (sem) -> sem.start
              semester = _.last semesters
            self.setActiveSemester(semester)
          d.resolve()
    return d.promise
  loadUser = () ->
    if not user
      user = {} 
    d = $q.defer()
    d.resolve()
    return d.promise
  $q.all([loadInstitute(),loadSemester(),loadUser()]).finally deferred.resolve
  this.setActiveInstitute = (institute) ->
    activeInstitute = {name: institute.name, image: institute.image}
    $cookieStore.put("activeInstitute", institute)
    $rootScope.$$phase || $rootScope.$apply() 
  this.getActiveInstitute = () ->
    return activeInstitute
  this.setActiveSemester = (semester) ->
    activeSemester = {
      name: semester.name 
    }
    for s in ["start","end","regstart","regend"]
      activeSemester[s] = new Date(semester[s]).getTime()
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
