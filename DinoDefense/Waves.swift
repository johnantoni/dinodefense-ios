//
//  Waves.swift
//  DinoDefense
//
//  Created by Toby Stephens on 21/10/2015.
//  Copyright © 2015 razeware. All rights reserved.
//

import Foundation

struct Wave {
  let dinosaurCount: Int
  let dinosaurDelay: Double
  let dinosaurType: DinosaurType
}

class WaveManager {
  
  var currentWave = 0
  var currentWaveDinosaurCount = 0
  
  let waves: [Wave]
  
  let newWaveHandler: (waveNum: Int) -> Void
  let newDinosaurHandler: (mobType: DinosaurType) -> Void
  
  init(waves: [Wave],
    newWaveHandler: (waveNum: Int) -> Void,
    newDinosaurHandler: (dinosaurType: DinosaurType) -> Void) {
      self.waves = waves
      self.newWaveHandler = newWaveHandler
      self.newDinosaurHandler = newDinosaurHandler
  }
  
  func startNextWave() -> Bool {
    // 1
    if waves.count <= currentWave {
      return true
    }
    
    // 2
    self.newWaveHandler(waveNum: currentWave+1)
    
    // 3
    let wave = waves[currentWave]
    // 4
    currentWaveDinosaurCount = wave.dinosaurCount
    for m in 1...wave.dinosaurCount {
      // 5
      delay(wave.dinosaurDelay * Double(m), closure: { () -> () in
        self.newDinosaurHandler(mobType: wave.dinosaurType)
      })
    }
    
    // 6
    currentWave += 1
    
    // 7
    return false
  }
  
  func removeDinosaurFromWave() -> Bool {
    currentWaveDinosaurCount -= 1
    if currentWaveDinosaurCount <= 0 {
      return startNextWave()
    }
    return false
  }
  
}

