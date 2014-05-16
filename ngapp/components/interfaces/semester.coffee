angular.module('interfaces')
.service "semester", ($rootScope,$q,$modal,session) ->
  this.showModal = (staticModal) -> 
    d = $q.defer()
    staticModal = false if not staticModal
    backdrop = if staticModal then "static" else true
    modalInstance = $modal.open {
      backdrop: backdrop
      keyboard: staticModal
      templateUrl: "indexSemesters.html"
      controller: "semestersCtrl"        
      resolve: {
        activeSemester: () -> return session.getActiveSemester()
      }
    }
    modalInstance.result.then ((sem)->session.getActiveSemester(sem)),(err)->d.reject(err)
    return d.promise
  return this