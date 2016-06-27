//
//  GameScene.swift
//  DinoDefense
//
//  Created by Toby Stephens on 26/09/2015.
//  Copyright © 2015 razeware. All rights reserved.
//

import SpriteKit
import GameplayKit


class GameScene: GameSceneHelper {
  
  // A GameScene state machine
  lazy var stateMachine: GKStateMachine = GKStateMachine(states: [
    GameSceneReadyState(scene: self),
    GameSceneActiveState(scene: self),
    GameSceneWinState(scene: self),
    GameSceneLoseState(scene: self)
    ])
  
  // Update timing information
  var lastUpdateTimeInterval: NSTimeInterval = 0
  
  var entities = Set<GKEntity>()
  
  lazy var componentSystems: [GKComponentSystem] = {
    let animationSystem = GKComponentSystem(
      componentClass: AnimationComponent.self)
    let firingSystem = GKComponentSystem(componentClass: FiringComponent.self)
    let agentSystem = GKComponentSystem(componentClass: DinosaurAgent.self)
    return [animationSystem, firingSystem, agentSystem]
  }()
  
  var towerSelectorNodes = [TowerSelectorNode]()
  var placingTower = false
  var placingTowerOnNode = SKNode()
  
  let obstacleGraph = GKObstacleGraph(obstacles: [], bufferRadius: 32)
  
  var waveManager: WaveManager!
  
  override func didMoveToView(view: SKView) {
    super.didMoveToView(view)
    
    loadTowerSelectorNodes()
    
    let obstacleSpriteNodes = self["Sprites/Obstacle_*"] as! [SKSpriteNode]
    for obstacle in obstacleSpriteNodes {
      addObstacle(withNode: obstacle)
    }
    
    // Set the initial GameScene state
    stateMachine.enterState(GameSceneReadyState.self)
    
    startBackgroundMusic()
    
    let waves = [Wave(dinosaurCount: 5, dinosaurDelay: 3, dinosaurType: .TRex),
      Wave(dinosaurCount: 8, dinosaurDelay: 2, dinosaurType: .Triceratops),
      Wave(dinosaurCount: 10, dinosaurDelay: 2, dinosaurType: .TRex),
      Wave(dinosaurCount: 25, dinosaurDelay: 1, dinosaurType: .Triceratops),
      Wave(dinosaurCount: 1, dinosaurDelay: 1, dinosaurType: .TRexBoss)]
    waveManager = WaveManager(waves: waves,
      newWaveHandler: { (waveNum) -> Void in
        self.waveLabel.text = "Wave \(waveNum)/\(waves.count)"
        self.runAction(SKAction.playSoundFileNamed("NewWave.mp3",
          waitForCompletion: false))
      }, newDinosaurHandler: { (dinosaurType) -> Void in
        self.addDinosaur(dinosaurType)
    })
  }
  
  // Update per frame
  override func update(currentTime: NSTimeInterval) {
    super.update(currentTime)
    
    // No updates to perform if this scene isn't being rendered
    guard view != nil else { return }
    
    // Calculate the amount of time since update was last called
    let deltaTime = currentTime - lastUpdateTimeInterval
    lastUpdateTimeInterval = currentTime
    
    // Don't evaluate any updates if the scene is paused.
    if paused { return }
    
    // Update the level's state machine.
    stateMachine.updateWithDeltaTime(deltaTime)
    
    for componentSystem in componentSystems {
      componentSystem.updateWithDeltaTime(deltaTime)
    }
  }
  
  override func didFinishUpdate() {
    let dinosaurs: [DinosaurEntity] = entities.flatMap { entity in
      if let dinosaur = entity as? DinosaurEntity {
        return dinosaur
      }
      return nil
    }
    
    let towers: [TowerEntity] = entities.flatMap { entity in
      if let tower = entity as? TowerEntity {
        return tower
      }
      return nil
    }
    
    for tower in towers {
      // 1
      let towerType = tower.towerType
      // 2
      var target: DinosaurEntity?
      // 3
      for dinosaur in dinosaurs.filter({
        (dinosaur: DinosaurEntity) -> Bool in
        distanceBetween(tower.spriteComponent.node, nodeB:
          dinosaur.spriteComponent.node) < towerType.range}) {
            
            // 4
            if let t = target {
              if towerType.hasSlowingEffect {
                if !dinosaur.hasBeenSlowed && t.hasBeenSlowed {
                  target = dinosaur
                }
                else if dinosaur.hasBeenSlowed == t.hasBeenSlowed
                  && dinosaur.spriteComponent.node.position.x >
                  t.spriteComponent.node.position.x {
                    target = dinosaur
                }
              }
              else if dinosaur.spriteComponent.node.position.x > 
                t.spriteComponent.node.position.x {
                  target = dinosaur
              }
            } else {
              target = dinosaur
            }
            
      }
      
      // 5
      tower.firingComponent.currentTarget = target
    }
    
    for dinosaur in dinosaurs {
      if dinosaur.healthComponent.health <= 0 {
        let win = waveManager.removeDinosaurFromWave()
        if win {
          stateMachine.enterState(GameSceneWinState.self)
        }
        
        dinosaur.removeEntityFromScene(true)
        stopDinosaurMoving(dinosaur)
        entities.remove(dinosaur)
        
        gold += dinosaur.dinosaurType.goldReward
        updateHUD()
      }
      else if dinosaur.spriteComponent.node.position.x > 1124 {
        waveManager.removeDinosaurFromWave()
        
        //1
        baseLives -= dinosaur.dinosaurType.baseDamage
        // 2
        updateHUD()
        // 3
        self.runAction(baseDamageSoundAction)
        
        // 4
        if baseLives <= 0 {
          stateMachine.enterState(GameSceneLoseState.self)
        }
        
        dinosaur.removeEntityFromScene(false)
        stopDinosaurMoving(dinosaur)
        entities.remove(dinosaur)
      }
    }
    
    // 1
    let ySortedEntities = entities.sort {
      let nodeA = $0.0.componentForClass(SpriteComponent.self)!.node
      let nodeB = $0.1.componentForClass(SpriteComponent.self)!.node
      return nodeA.position.y > nodeB.position.y
    }
    
    // 2
    var zPosition = GameLayer.zDeltaForSprites
    for entity in ySortedEntities {
      // 3 - Get the entity's sprite component
      let spriteComponent = entity.componentForClass(SpriteComponent.self)
      
      // 4 - Get the sprite component's node
      let node = spriteComponent!.node
      
      // 5 - Set the node's zPosition to zPosition
      node.zPosition = zPosition
      
      // 6 - Increment zPosition by GameLayer.zDeltaForSprites
      zPosition += GameLayer.zDeltaForSprites
    }
  }
  
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    guard let touch = touches.first else {
      return
    }
    print("Touch: \(touch.locationInNode(self))")

    if let _ = stateMachine.currentState as? GameSceneReadyState {
      stateMachine.enterState(GameSceneActiveState.self)
      return
    }
    
    let touchedNodes: [SKNode] = self.nodesAtPoint(touch.locationInNode(self)).flatMap { node in
      if let nodeName = node.name where nodeName.hasPrefix("Tower_") {
        return node
      }
      return nil
    }
    
    if touchedNodes.count == 0 {
      hideTowerSelector()
      return
    }
    
    let touchedNode = touchedNodes[0]
    
    if placingTower {
      let touchedNodeName = touchedNode.name!
      
      if touchedNodeName == "Tower_Icon_WoodTower" {
        addTower(.Wood, position: placingTowerOnNode.position)
      }
      else if touchedNodeName == "Tower_Icon_RockTower" {
        addTower(.Rock, position: placingTowerOnNode.position)
      }
      
      hideTowerSelector()
    }
    else {
      placingTowerOnNode = touchedNode
      showTowerSelector(atPosition: touchedNode.position)
    }
  }
  
  func startFirstWave() {
    print("Start first wave!")
    
    waveManager.startNextWave()
    
    baseLabel.runAction(SKAction.fadeAlphaTo(1.0, duration: 0.5))
    waveLabel.runAction(SKAction.fadeAlphaTo(1.0, duration: 0.5))
    goldLabel.runAction(SKAction.fadeAlphaTo(1.0, duration: 0.5))
  }
  
  func addEntity(entity: GKEntity) {
    // 1
    entities.insert(entity)
    
    for componentSystem in self.componentSystems {
      componentSystem.addComponentWithEntity(entity)
    }
    
    // 2
    if let spriteNode = entity.componentForClass(
      SpriteComponent.self)?.node {
        
        addNode(spriteNode, toGameLayer: .Sprites)
        
        // TODO: More here!
        
        // 1
        if let shadowNode = entity.componentForClass(
          ShadowComponent.self)?.node {
            
            // 2
            addNode(shadowNode, toGameLayer: .Shadows)
            
            // 3
            let xRange = SKRange(constantValue: shadowNode.position.x)
            let yRange = SKRange(constantValue: shadowNode.position.y)
            let constraint = SKConstraint.positionX(xRange, y: yRange)
            constraint.referenceNode = spriteNode       
            shadowNode.constraints = [constraint]
        }
    }
  }
  
  func addDinosaur(dinosaurType: DinosaurType) {
    var startPosition = CGPointMake(-200, 384)
    startPosition.y = startPosition.y + (CGFloat(random.nextInt()-10)*10)
    let endPosition = CGPointMake(1224, 384)
    
    let dinosaur = DinosaurEntity(dinosaurType: dinosaurType)
    let dinoNode = dinosaur.spriteComponent.node
    dinoNode.position = startPosition
    setDinosaurOnPath(dinosaur, toPoint: endPosition)
    
    addEntity(dinosaur)
    
    dinosaur.animationComponent.requestedAnimationState = .Walk
  }
  
  func addTower(towerType: TowerType, position: CGPoint) {
    if gold < towerType.cost {
      self.runAction(SKAction.playSoundFileNamed("NoBuildTower.mp3", waitForCompletion: false))
      return
    }
    
    gold -= towerType.cost
    updateHUD()
    
    placingTowerOnNode.removeFromParent()
    self.runAction(SKAction.playSoundFileNamed("BuildTower.mp3", waitForCompletion: false))
    
    let towerEntity = TowerEntity(towerType: towerType)
    towerEntity.spriteComponent.node.position = position
    towerEntity.animationComponent.requestedAnimationState = .Idle
    addEntity(towerEntity)
    
    addObstaclesToObstacleGraph(
      towerEntity.shadowComponent.createObstaclesAtPosition(position))
    
    recalculateDinosaurPaths()
  }
  
  func addObstacle(withNode node: SKSpriteNode) {
    // 1 - Store nodes's position
    let nodePosition = node.position
    
    // 2 - Remove node from parent
    node.removeFromParent()
    
    // 3 - Create obstacle entity
    let obstacleEntity = ObstacleEntity(withNode: node)
    
    // 4 - Add obstacle entity to scene
    addEntity(obstacleEntity)
    
    // 5 - Create obstacles from shadow component
    let obstacles = obstacleEntity.shadowComponent.createObstaclesAtPosition(nodePosition)
    
    // 6 - Add obstacles to obstacle graph
    addObstaclesToObstacleGraph(obstacles)
  }
  
  func setDinosaurOnPath(dinosaur: DinosaurEntity, toPoint point: CGPoint) {
    let dinosaurNode = dinosaur.spriteComponent.node
    
    // 1
    let startNode = GKGraphNode2D(
      point: vector_float2(dinosaurNode.position))
    obstacleGraph.connectNodeUsingObstacles(startNode)
    
    // 2
    let endNode = GKGraphNode2D(point: vector_float2(point))
    obstacleGraph.connectNodeUsingObstacles(endNode)
    
    // 3
    let pathNodes = obstacleGraph.findPathFromNode(
      startNode, toNode: endNode) as! [GKGraphNode2D]
    
    // 4
    obstacleGraph.removeNodes([startNode, endNode])
    
    switch dinosaur.dinosaurType {
    case .TRex, .TRexBoss:
      dinosaurNode.removeActionForKey("move")
      
      var pathActions = [SKAction]()
      var lastNodePosition = startNode.position
      for node2D in pathNodes {
        
        let nodePosition = CGPoint(node2D.position)
        
        let actionDuration =
        NSTimeInterval(lastNodePosition.distanceTo(node2D.position) /
          dinosaur.dinosaurType.speed)
        
        let pathNodeAction = SKAction.moveTo(
          nodePosition, duration: actionDuration)
        
        pathActions.append(pathNodeAction)
        lastNodePosition = node2D.position
      }
      
      dinosaurNode.runAction(SKAction.sequence(pathActions), withKey: "move")
      
    case .Triceratops:
      if pathNodes.count > 1 {
        let dinosaurPath = GKPath(graphNodes: pathNodes, radius: 32.0)
        dinosaur.agent!.behavior = DinosaurPathBehavior.pathBehavior(
          forAgent: dinosaur.agent!,
          onPath: dinosaurPath,
          avoidingObstacles: obstacleGraph.obstacles)
      }
    }
  }
  
  func recalculateDinosaurPaths() {
    // 1
    let endPosition = CGPointMake(1224, 384)
    
    // 2
    let dinosaurs: [DinosaurEntity] = entities.flatMap { entity in
      if let dinosaur = entity as? DinosaurEntity {
        if dinosaur.healthComponent.health <= 0 {return nil}
        return dinosaur
      }
      return nil
    }
    
    // 3
    for dinosaur in dinosaurs {
      setDinosaurOnPath(dinosaur, toPoint: endPosition)
    }
  }
  
  func stopDinosaurMoving(dinosaur: DinosaurEntity) {
    switch dinosaur.dinosaurType {
    case .TRex, .TRexBoss:
      let dinosaurNode = dinosaur.spriteComponent.node
      dinosaurNode.removeActionForKey("move")
    case .Triceratops:
      dinosaur.agent!.maxSpeed = 0.1
    }
  }
  
  func addObstaclesToObstacleGraph(newObstacles: [GKPolygonObstacle]) {
    obstacleGraph.addObstacles(newObstacles)
  }
  
  func loadTowerSelectorNodes() {
    // 1
    let towerTypeCount = TowerType.allValues.count
    
    // 2
    let towerSelectorNodePath: String = NSBundle.mainBundle()
      .pathForResource("TowerSelector", ofType: "sks")!
    let towerSelectorNodeScene = NSKeyedUnarchiver.unarchiveObjectWithFile(
      towerSelectorNodePath) as! SKScene
    for t in 0..<towerTypeCount {
      // 3
      let towerSelectorNode = (towerSelectorNodeScene.childNodeWithName(
        "MainNode"))!.copy() as! TowerSelectorNode
      // 4
      towerSelectorNode.setTower(TowerType.allValues[t],
        angle: ((2*π)/CGFloat(towerTypeCount))*CGFloat(t))
      // 5
      towerSelectorNodes.append(towerSelectorNode)
    }
  }
  
  func showTowerSelector(atPosition position: CGPoint) {
    // 1
    if placingTower == true {return}
    placingTower = true
    
    // 2
    self.runAction(SKAction.playSoundFileNamed("Menu.mp3", waitForCompletion: false))
    
    for towerSelectorNode in towerSelectorNodes {
      // 3
      towerSelectorNode.position = position
      // 4
      gameLayerNodes[.Hud]!.addChild(towerSelectorNode)
      // 5
      towerSelectorNode.show()
    }
  }
  
  func hideTowerSelector() {
    if placingTower == false { return }
    placingTower = false
    
    self.runAction(SKAction.playSoundFileNamed("Menu.mp3", waitForCompletion: false))
    
    for towerSelectorNode in towerSelectorNodes {
      towerSelectorNode.hide {
        towerSelectorNode.removeFromParent()
      }
    }
  }
  
}


