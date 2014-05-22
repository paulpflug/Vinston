angular.module("StructureModule",["oc.lazyLoad","ui.tree"])
.controller "structureCtrl", ($scope, $filter,$q , semesterData,session, generate) ->
  $scope.finished = false
  $scope.structure = new semesterData {
    connection: "'structures.'+session.getActiveSemester().name"
    filterBy: {institute:"session.getActiveInstitute().name"}
    scope: $scope.$new()
    nameOfItem: "name"
    nameOfDatabase: "Struktur"
    singleItem: true
    }
  $q.all([$scope.structure.loaded])
  .finally () ->  
    $scope.finished = true
  $scope.addRootElement = () ->
    if not $scope.structure.data.institute
      $scope.structure.insert {
        institute: session.getActiveInstitute().name
        nodes: [{name:"",nodes:[]}]
      }
      $scope.save()
    if $scope.structure.data.nodes and $scope.structure.data.nodes.length == 0 
      $scope.structure.data.nodes.push([{name:"",nodes:[]}])
      $scope.save()
  $scope.treeOptions = {
    dropped: (event) ->
      delete event.source.nodeScope.$modelValue.$$hashKey
      if event.source.nodesScope != event.dest.nodesScope
        $scope.save()
  }
  $scope.save = () -> 
    $scope.structure.save().then () ->
      $scope.structure.reload()
  $scope.cleanTree = (tree) ->
    delete tree.$$hashKey
    for node in tree.nodeScope
      $scope.cleanTree(node)

  $scope.addNode = (scope) ->
    nodeData = scope.$modelValue;
    scope.collapsed = false
    nodeData.nodes = [] if not nodeData.nodes
    nodeData.nodes.push {name:"", nodes: [], $$hashKey: generate.token(3)}
    $scope.save()
  

  $scope.deleteNode = (scope) ->

    parent = scope.$parentNodesScope
    parent.removeNode(scope)
    $scope.save()