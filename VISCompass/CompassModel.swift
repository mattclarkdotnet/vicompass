//
//  CompassModel.swift
//  VISCompass
//
//  Created by Matt Clark on 21/12/2015.
//  Copyright © 2015 mattclark.net. All rights reserved.
//

import Foundation
import CoreLocation

enum Turn {
    case Port
    case Stbd
}

struct Correction {
    var direction: Turn
    var amount: CLLocationDegrees
    var required: Bool
}

class CompassModel {
    var headingTarget: CLLocationDegrees?
    var diffTolerance: CLLocationDegrees = 5
    var responsivenessIndex = 2
    
    let responsivenessWindows: [Double] = [10.0, 6.0, 3.5, 2.0, 1.0]
    let tackDegrees = 100.0
    let headingUpdates: ObservationHistory = ObservationHistory(deltaFunc: CompassModel.correctionDegrees, window_secs: 10)
    
    static func correctionDegrees(current: CLLocationDegrees, target: CLLocationDegrees) -> CLLocationDegrees {
        let difference = target - current
        if difference == -180 {
            return 180
        } else if difference > 180 {
            return difference - 360
        } else if difference < -180 {
            return difference + 360
        } else {
            return difference
        }
    }
    
    func correction() -> Correction? {
        let headingCurrent = smoothedHeading()
        if headingTarget == nil || headingCurrent == nil { return nil }
        let c = CompassModel.correctionDegrees(headingCurrent!, target: headingTarget!)
        return Correction(direction: c < 0 ? Turn.Port : Turn.Stbd, amount: c, required: abs(c) > diffTolerance)
    }
    
    func resonsivenessWindowSecs() -> Double {
        return responsivenessWindows[responsivenessIndex]
    }
    
    func setResponsiveness(index: Int) {
        responsivenessIndex = index
        headingUpdates.window_secs = resonsivenessWindowSecs()
    }
    
    func smoothedHeading() -> CLLocationDegrees? {
        let s = headingUpdates.smoothed(NSDate())
        if s == nil { return nil }
        return s!
    }
    
    func updateCurrentHeading(newheading: CLLocationDegrees) {
        log.debug("updateCurrentHeading got: \(newheading)")
        headingUpdates.add_observation(Observation(v: newheading, t: NSDate()))
        // Don't update the UI, wait for the timer to do so
    }
    
    func modifyTarget(delta: Double) {
        if headingTarget != nil {
            headingTarget = (headingTarget! + delta) % 360.0
        }
    }
    
    func tackPort() {
        modifyTarget(-tackDegrees)
    }
    
    func tackStbd() {
        modifyTarget(tackDegrees)
    }
    
}
