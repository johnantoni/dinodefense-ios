//
//  ProjectileEntity.swift
//  DinoDefense
//
//  Created by Toby Stephens on 20/10/2015.
//  Copyright © 2015 razeware. All rights reserved.
//

import SpriteKit
import GameplayKit

class ProjectileEntity: GKEntity {
  
  var spriteComponent: SpriteComponent!
  
  init(towerType: TowerType) {
    super.init()
    
    let texture = SKTexture(imageNamed:
      "\(towerType.rawValue)Projectile")
    spriteComponent = SpriteComponent(entity: self,
      texture: texture, size: texture.size())
    addComponent(spriteComponent)
  }
  
}

