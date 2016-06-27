//
//  DinosaurEntity.swift
//  DinoDefense
//
//  Created by Toby Stephens on 20/10/2015.
//  Copyright © 2015 razeware. All rights reserved.
//

import Foundation
import UIKit
import GameplayKit
import SpriteKit

enum DinosaurType: String {
  case TRex = "T-Rex"
  case Triceratops = "Triceratops"
  case TRexBoss = "T-RexBoss"
  
  var health: Int {
    switch self {
    case .TRex: return 60
    case .Triceratops: return 40
    case .TRexBoss: return 1000
    }
  }
  
  var speed: Float {
    switch self {
    case .TRex: return 100
    case .Triceratops: return 150
    case .TRexBoss: return 50
    }
  }
  
  var baseDamage: Int {
    switch self {
    case .TRex: return 2
    case .Triceratops: return 1
    case .TRexBoss: return 5
    }
  }
  
  var goldReward: Int {
    switch self {
    case .TRex: return 10
    case .Triceratops: return 5
    case .TRexBoss: return 50
    }
  }
}

class DinosaurAgent: GKAgent2D {
}

class DinosaurEntity: GKEntity, GKAgentDelegate {
  
  // 1
  let dinosaurType: DinosaurType
  var spriteComponent: SpriteComponent!
  var shadowComponent: ShadowComponent!
  var animationComponent: AnimationComponent!
  var healthComponent: HealthComponent!
  
  var agent: DinosaurAgent?
  
  var hasBeenSlowed = false
  
  // 2
  init(dinosaurType: DinosaurType) {
    self.dinosaurType = dinosaurType
    super.init()
    
    // 3
    let size: CGSize
    switch dinosaurType {
    case .TRex, .TRexBoss:
      size = CGSizeMake(203, 110)
    case .Triceratops:
      size = CGSizeMake(142, 74)
    }
    
    // 4
    let textureAtlas = SKTextureAtlas(named: dinosaurType.rawValue)
    let defaultTexture = textureAtlas.textureNamed("Walk__01.png")
    
    // 5
    spriteComponent = SpriteComponent(entity: self,
      texture: defaultTexture, size: size)
    addComponent(spriteComponent)
    
    let shadowSize = CGSizeMake(size.width, size.height * 0.3)
    shadowComponent = ShadowComponent(size: shadowSize,
      offset: CGPointMake(0.0, -size.height/2 + shadowSize.height/2))
    addComponent(shadowComponent)
    
    animationComponent = AnimationComponent(node: spriteComponent.node, textureSize: size, animations: loadAnimations())
    addComponent(animationComponent)
    
    healthComponent = HealthComponent(parentNode: spriteComponent.node,
      barWidth: size.width,
      barOffset: size.height,
      health: dinosaurType.health)
    addComponent(healthComponent)
    
    if dinosaurType == .Triceratops {
      agent = DinosaurAgent()
      agent!.delegate = self
      agent!.maxSpeed = dinosaurType.speed
      agent!.maxAcceleration = 200.0
      agent!.mass = 0.1
      agent!.radius = Float(size.width * 0.5)
      agent!.behavior = GKBehavior()
      addComponent(agent!)
    }
  }
  
  func agentWillUpdate(agent: GKAgent) {
    self.agent!.position = float2(x: Float(spriteComponent.node.position.x),
      y: Float(spriteComponent.node.position.y))
  }
  
  func agentDidUpdate(agent: GKAgent) {
    let agentPosition = CGPoint(self.agent!.position)
    spriteComponent.node.position = CGPoint(x: agentPosition.x,
      y: agentPosition.y)
  }
  
  func removeEntityFromScene(death: Bool) {
    if death {
      // Set the death animation
      animationComponent.requestedAnimationState = .Dead
      let soundAction = SKAction.playSoundFileNamed(
        "\(dinosaurType.rawValue)Dead.mp3",
        waitForCompletion: false)
      let waitAction = SKAction.waitForDuration(2.0)
      let removeAction = SKAction.runBlock({ () -> Void in
        self.spriteComponent.node.removeFromParent()
        self.shadowComponent.node.removeFromParent()
      })
      spriteComponent.node.runAction(SKAction.sequence(
        [soundAction, waitAction, removeAction]))
    }
    else {
      spriteComponent.node.removeFromParent()
      shadowComponent.node.removeFromParent()
    }
  }
  
  func slowed(slowFactor: Float) {
    hasBeenSlowed = true
    
    animationComponent.node.color = SKColor.cyanColor()
    animationComponent.node.colorBlendFactor = 1.0
    switch dinosaurType {
    case .TRex, .TRexBoss:
      spriteComponent.node.speed = CGFloat(slowFactor)
    case .Triceratops:
      agent!.maxSpeed = dinosaurType.speed * slowFactor
    }
  }
  
  func loadAnimations() -> [AnimationState: Animation] {
    let textureAtlas = SKTextureAtlas(named: dinosaurType.rawValue)
    var animations = [AnimationState: Animation]()
    
    animations[.Walk] = AnimationComponent.animationFromAtlas(
      textureAtlas,
      withImageIdentifier: "Walk",
      forAnimationState: .Walk)
    animations[.Hit] = AnimationComponent.animationFromAtlas(
      textureAtlas,
      withImageIdentifier: "Hurt",
      forAnimationState: .Hit,
      repeatTexturesForever: false)
    animations[.Dead] = AnimationComponent.animationFromAtlas(
      textureAtlas,
      withImageIdentifier: "Dead",
      forAnimationState: .Dead,
      repeatTexturesForever: false)
    
    return animations
  }
}


