angular.module "RootModule"
.controller "serverConfigCtrl", ($scope, $q, config) ->
  socketConfig = io.connect("/config")
  $scope.loaded = false  
  # initialize
  config.get "mongoConnection"
  .then (response)->
    if response.success
      $scope.mongoConnection = response.content
      $scope.loaded = true