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

class CompassModel: NSObject, CLLocationManagerDelegate {
    var diffTolerance: CLLocationDegrees = 5
    var headingTarget: CLLocationDegrees?
    var headingCurrent: CLLocationDegrees?
    
    var locationManager: CLLocationManager? = nil
    private let headingFilter: CLLocationDegrees = 1.0
    private var responsivenessIndex = 2
    private let responsivenessWindows: [Double] = [10.0, 6.0, 3.0, 1.5, 0.75]
    private let tackDegrees = 100.0
    private let headingUpdates: ObservationHistory = ObservationHistory(deltaFunc: CompassModel.correctionDegrees, window_secs: 10)
    
    override init() {
        super.init()
        if CLLocationManager.headingAvailable() {
            locationManager = CLLocationManager()
            locationManager!.delegate = self
            locationManager!.headingFilter = headingFilter
            locationManager!.startUpdatingHeading()
        }
    }
    
    //
    // internal interface
    //
    
    func isUsingCompass() -> Bool {
        return locationManager != nil
    }
    
    func correction() -> Correction? {
        if let hc = smoothedHeading(), let ht = headingTarget {
            let c = CompassModel.correctionDegrees(hc, target: ht)
            return Correction(direction: c < 0 ? Turn.Port : Turn.Stbd,
                amount: c,
                required: abs(c) > diffTolerance)
        } else {
            return nil
        }
    }
    
    func smoothedHeading() -> CLLocationDegrees? {
        return headingUpdates.smoothed(NSDate())
    }
    
    func updateCurrentHeading(newheading: CLLocationDegrees) {
        self.headingCurrent = newheading
        headingUpdates.add_observation(Observation(v: newheading, t: NSDate()))
    }
    
    func setResponsiveness(index: Int) {
        responsivenessIndex = index
        headingUpdates.window_secs = resonsivenessWindowSecs()
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
    
    //CLLocationManagerDelegate
    func locationManager(manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        updateCurrentHeading(newHeading.magneticHeading)
    }
    
    class func correctionDegrees(current: CLLocationDegrees, target: CLLocationDegrees) -> CLLocationDegrees {
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
    
    func resonsivenessWindowSecs() -> Double {
        return responsivenessWindows[responsivenessIndex]
    }
}
