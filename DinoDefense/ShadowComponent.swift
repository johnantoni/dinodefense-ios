//
//  ShadowComponent.swift
//  DinoDefense
//
//  Created by Toby Stephens on 20/10/2015.
//  Copyright © 2015 razeware. All rights reserved.
//

import Foundation
import GameplayKit
import SpriteKit

class ShadowComponent: GKComponent {
  
  let node: SKShapeNode
  
  let size: CGSize
  
  init(size: CGSize, offset: CGPoint) {
    self.size = size
    
    node = SKShapeNode(ellipseOfSize: size)
    node.fillColor = SKColor.blackColor()
    node.strokeColor = SKColor.blackColor()
    node.alpha = 0.2
    node.position = offset
  }
  
  func createObstaclesAtPosition(position: CGPoint) -> [GKPolygonObstacle] {
    let centerX = position.x + node.position.x
    let centerY = position.y + node.position.y
    let left = float2(CGPointMake(centerX - size.width/2, centerY))
    let top = float2(CGPointMake(centerX, centerY + size.height/2))
    let right = float2(CGPointMake(centerX + size.width/2, centerY))
    let bottom = float2(CGPointMake(centerX, centerY - size.height/2))
    var vertices = [left, bottom, right, top]
    
    let obstacle = GKPolygonObstacle(points: &vertices, count: 4)
    return [obstacle]
  }
  
}

