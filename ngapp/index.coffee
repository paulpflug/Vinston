angular.module("vinstonApp")
.controller("appCtrl", ($scope, $modal,config , session) ->
  $scope.session = session
  $scope.showInstitutes = () -> 
    modalInstance = $modal.open {
      backdrop: if session.getActiveInstitute() then true else 'static'
      templateUrl: "indexInstitutes.html"
      controller: ($scope, $modalInstance,config, activeInstitute) -> 
        $scope.institutes = []
        $scope.ready = false
        $scope.activeInstitute = activeInstitute
        config.get("institutes").then (data) ->
            $scope.institutes = data 
            $scope.ready = true
        $scope.setInstitute = (inst) -> 
          $modalInstance.close(inst)
      resolve: {
        activeInstitute: () -> return session.getActiveInstitute()
        config: () -> return config
      }
    }
    modalInstance.result.then (inst)->
      $scope.setActiveInstitute(inst)
      
  $scope.setActiveInstitute = (inst) ->
    session.setActiveInstitute(inst)
    $scope.activeInstiute = inst
    $scope.$$phase || $scope.$apply() 
  $scope.activeInstiute = session.getActiveInstitute()
  if not $scope.activeInstiute
    $scope.showInstitutes()
  else
    $scope.activeInstiute

  $scope.showLogin = () -> 
    modalInstance = $modal.open {
      templateUrl: "indexLogin.html"
      controller: ($scope, $modalInstance) -> 
        $scope.setUser = (user) -> 
          $modalInstance.close(user)
    }
    modalInstance.result.then (user)->
      $scope.setUser(user)
  $scope.setUser = (user) ->
    $scope.user = user
).filter("isNot", () ->
  return (array,filter,property) ->
    if filter
      result = []
      for text in array
        t = text
        if property 
          if t[property]
            t = t[property]
          if filter[property]
            filter = filter[property]
        if t != filter
          result.push(text)
      return result
    else
      return array
)

