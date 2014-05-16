angular.module('interfaces')
.service "session", ($rootScope,$cookieStore) ->
  activeInstitute = $cookieStore.get("activeInstitute")
  activeInstitute = "" if not activeInstitute
  activeSemester = $cookieStore.get("activeSemester")
  activeSemester = "" if not activeSemester
  user = $cookieStore.get("user")
  user = {} if not user
  this.setActiveInstitute = (institute) ->
    activeInstitute = {name: institute.name, image: institute.image}
    $cookieStore.put("activeInstitute", institute)
  this.getActiveInstitute = () ->
    return activeInstitute
  this.setActiveSemester = (semester) ->
    semester = {name: semester.name, start: semester.start, end:semester.end}
    $cookieStore.put("activeInstitute", semester)
  this.getActiveSemester= () ->
    return activeSemester
  this.setUser = (newUser) ->
    $cookieStore.put("user", newUser)
    user = newUser
  this.getUser = () ->
    return user
  return this
