angular.module("vinstonApp")
.controller "semestersCtrl", ($scope, $modalInstance,$location,auth,config, activeSemester) -> 
  $scope.semesters = []
  $scope.ready = false
  $scope.activeSemester = activeSemester
  $scope.docent = auth.inGroup("docent")
  $scope.now = Date.now()
  config.get("semesters").then (response) ->
    if response.success and response.content
      $scope.semesters = _.cloneDeep _.sortBy response.content, (sem) -> sem.start
      for sem in $scope.semesters
        for s in ["start","end","regstart","regend"]
          sem[s] = new Date(sem[s]).getTime()
      for sem in $scope.semesters
        sem.class = false
        if sem.start < $scope.now and $scope.now < sem.end
          sem.class = "btn-primary"
        if sem.regstart < $scope.now and $scope.now < sem.regend
          sem.class = "btn-info"
        if sem.name == activeSemester.name
          sem.class = "btn-default"
      $scope.semesters.reverse()
      $scope.ready = true
    else
      $modalInstance.dismiss()
  $scope.setSemester = (semester) -> 
    $modalInstance.close(semester)
