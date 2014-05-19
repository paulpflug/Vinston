angular.module("StructureModule",["oc.lazyLoad","ui.tree"])
.controller "structureCtrl", ($scope, $filter,$q , semesterData,session, generate) ->
  $scope.finished = false
  $scope.structure = new semesterData "structure", $scope, {
    nameOfItem: "name"
    nameOfDatabase: "Struktur"
    singleItem: true
    },{find:{institute:session.getActiveInstitute().name}}
  $scope.$watch "session.getActiveInstitute()",
    (() -> 
      $scope.structure.reload {
        find:
          institute:session.getActiveInstitute().name
        }
      .then $scope.addRootElement),true
  $q.all([$scope.structure.loaded])
  .then $scope.addRootElement
  .finally () ->  
    $scope.finished = true
  $scope.addRootElement = () ->
    if not $scope.structure.data.institute
      $scope.structure.insert {
        institute: session.getActiveInstitute().name
        nodes: [{name:"",nodes:[]}]
      }
    if $scope.structure.data.nodes and $scope.structure.data.nodes.length == 0 
      $scope.structure.data.nodes.push([{name:"",nodes:[]}])
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