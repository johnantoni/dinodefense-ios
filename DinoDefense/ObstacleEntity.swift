//
//  ObstacleEntity.swift
//  DinoDefense
//
//  Created by Toby Stephens on 21/10/2015.
//  Copyright © 2015 razeware. All rights reserved.
//

import SpriteKit
import GameplayKit

class ObstacleEntity: GKEntity {
  // 1
  var spriteComponent: SpriteComponent!
  // 2
  var shadowComponent: ShadowComponent!
  
  // 3
  init(withNode node: SKSpriteNode) {
    super.init()
    
    // 4
    spriteComponent = SpriteComponent(entity: self, texture: node.texture!, size: node.size)
    addComponent(spriteComponent)
    
    // 5
    let shadowSize = CGSizeMake(node.size.width*1.1, node.size.height * 0.6)
    shadowComponent = ShadowComponent(size: shadowSize, offset: CGPointMake(0.0, -node.size.height*0.35))
    addComponent(shadowComponent)
    
    // 6
    spriteComponent.node.position = node.position
    node.position = CGPointZero
    spriteComponent.node.addChild(node)
  }
}


