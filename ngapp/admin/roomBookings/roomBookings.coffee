angular.module "AdminModule"
.controller "roomBookingsCtrl", ($scope, $q , $modal,session, semesterData ) ->
  $scope.finished = false
  $scope.roomBookings = new semesterData {
    scope: $scope.$new()
    connection: "'roomBookings.'+session.getActiveSemester().name"
    nameOfItem: "name"
    nameOfDatabase: "Raum Buchung"
    useDiffs: true
    showDeleted: true
    }
  $q.all([$scope.roomBookings.loaded])
  .finally () ->  $scope.finished = true 
