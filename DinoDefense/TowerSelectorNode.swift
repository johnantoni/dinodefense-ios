//
//  TowerSelectorNode.swift
//  DinoDefense
//
//  Created by Toby Stephens on 21/10/2015.
//  Copyright © 2015 razeware. All rights reserved.
//

import SpriteKit

class TowerSelectorNode: SKNode {
  
  var showAction = SKAction()
  var hideAction = SKAction()
  
  var costLabel: SKLabelNode {
    return self.childNodeWithName("CostLabel") as! SKLabelNode
  }
  
  var towerIcon: SKSpriteNode {
    return self.childNodeWithName("TowerIcon") as! SKSpriteNode
  }
  
  override init() {
    super.init()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  func setTower(towerType: TowerType, angle: CGFloat) {
    // Set the name and icon
    towerIcon.texture = SKTexture(imageNamed: towerType.rawValue)
    towerIcon.name = "Tower_Icon_\(towerType.rawValue)"
    
    // Set the cost
    costLabel.text = "\(towerType.cost)"
    
    self.zRotation = 180.degreesToRadians()
    
    let rotateAction = SKAction.rotateByAngle(
      180.degreesToRadians(),
      duration: 0.2)
    
    let moveAction = SKAction.moveByX(
      cos(angle) * 50,
      y: sin(angle) * 50,
      duration: 0.2)
    
    showAction = SKAction.group([rotateAction, moveAction])
    hideAction = showAction.reversedAction()
  }
  
  func show() {
    self.runAction(showAction)
  }
  
  func hide(completion: () -> ()) {
    self.runAction(SKAction.sequence([
      hideAction, SKAction.runBlock(completion)]))
  }
  
}

