mod = angular.module('interfaces')

mod.service "institute", ($rootScope,$q,$modal,session) ->
  this.showModal = (staticModal) -> 
    d = $q.defer()
    staticModal = false if not staticModal
    backdrop = if staticModal then "static" else true
    modalInstance = $modal.open {
      backdrop: backdrop
      keyboard: staticModal
      templateUrl: "indexInstitutes.html"
      controller: "institutesCtrl"        
      resolve: {
        activeInstitute: () -> return session.getActiveInstitute()
      }
    }
    modalInstance.result.then ((inst)->session.setActiveInstitute(inst)),(err)->d.reject(err)
    return d.promise
  return this