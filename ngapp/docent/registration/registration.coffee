angular.module "DocentModule"
.controller "registrationCtrl", ($scope,$q,semesterData,session,generate,auth,config) ->
  $scope.finished = false
  $scope.structure = new semesterData {
    connection: "'structures.'+session.getActiveSemester().name"
    filterBy: {institute: "session.getActiveInstitute().name"}
    scope: $scope.$new()
    nameOfItem: "name"
    nameOfDatabase: "Struktur"
    singleItem: true
    }
  $scope.courses = new semesterData {
    connection: "'courses.'+session.getActiveSemester().name"
    filterBy: {institute: "session.getActiveInstitute().name"}
    scope: $scope.$new()
    nameOfItem: "name"
    nameOfDatabase: "Veranstaltung"
    }
  populate = () ->
    sorted = {}
    populateNodes = (nodes) ->
      for node in nodes
        if node.nodes and node.nodes.length > 0
          populateNodes node.nodes
        else 
          if sorted[node.abbreviation]
            node.courses = sorted[node.abbreviation] 
            delete sorted[node.abbreviation]
          now = Date.now()  
          sem = session.getActiveSemester()
          if auth.inGroup("admin") or (sem.regstart < now and sem.regend > now)
            node.courses = [] if not node.courses
            node.courses.push {
              name: "Veranstaltung anlegen"
            }          
    for course in $scope.courses.data
      for tie in course.structureTies
        sorted[tie] = [] if not sorted[tie] 
        sorted[tie].push course
    populateNodes $scope.structure.data.nodes
    if Object.keys(sorted).length > 0
      node = {abbreviation:"sonst",name:"Sonstige",courses: []}
      for key,remaining of sorted
        node.courses.push remaining
      $scope.structure.data.nodes.push node
  $scope.getSemesterIndex = () ->
    currentSemester = session.getActiveSemester()
    _.findIndex $scope.semesters, (sem) -> sem.name == currentSemester.name
  config.get("semesters")
  .then (response) ->
    if response.success 
      if response.content
        semesters = response.content
        $scope.semesters = _.sortBy semesters, (sem) -> sem.start
        $scope.lastCourses = new semesterData {
          connection: "'courses.'+semesters[getSemesterIndex()-1].name"
          filterBy: {institute: "session.getActiveInstitute().name"}
          scope: $scope.$new()
          nameOfItem: "name"
          nameOfDatabase: "Veranstaltung"
          }
        $scope.beforLastCourses = new semesterData {
          connection: "'courses.'+semesters[getSemesterIndex()-2].name"
          filterBy: {institute: "session.getActiveInstitute().name"}
          scope: $scope.$new()
          nameOfItem: "name"
          nameOfDatabase: "Veranstaltung"
          }
    $q.all([
      $scope.structure.loaded
      $scope.courses.loaded
      $scope.lastCourses.loaded
      $scope.beforLastCourses.loaded
      ])
    .finally () ->  
      populate()
      $scope.finished = true 