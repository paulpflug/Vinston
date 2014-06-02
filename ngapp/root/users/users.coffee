angular.module "RootModule"
.controller "usersCtrl", ($scope,$q,semesterDataCollection,auth) ->
  $scope.finished = false
  $scope.users = new semesterDataCollection {
    scope: $scope.$new()
    connection: "'users'"
    nameOfItem: "name"
    nameOfDatabase: "Benutzer"
    orderBy: {"'-lastLogin'"}
    }
  $scope.groups = auth.groups
  $q.all([$scope.users.loaded])
  .finally () ->  $scope.finished = true   