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
    case port
    case stbd
    case none
}

struct Correction {
    var direction: Turn
    var amount: CLLocationDegrees
}

class CompassModel: NSObject, CLLocationManagerDelegate {
    var diffTolerance: CLLocationDegrees = 10
    var headingTarget: CLLocationDegrees?
    var headingCurrent: CLLocationDegrees?
    
    var locationManager: CLLocationManager? = nil
    fileprivate let headingFilter: CLLocationDegrees = 1.0
    fileprivate var responsivenessIndex = 2
    fileprivate let responsivenessWindows: [Double] = [10.0, 6.0, 3.0, 1.5, 0.75]
    fileprivate let headingUpdates: ObservationHistory = ObservationHistory(deltaFunc: CompassModel.correctionDegrees, window_secs: 10)
    
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
            if abs(c) < diffTolerance {
                return Correction(direction: Turn.none,
                                  amount: c)
            }
            else {
                return Correction(direction: c < 0 ? Turn.port : Turn.stbd,
                                  amount: c)
            }
        }
        else {
            return nil
        }
    }
    
    func smoothedHeading() -> CLLocationDegrees? {
        return headingUpdates.smoothed(Date())
    }
    
    func updateCurrentHeading(_ newheading: CLLocationDegrees) {
        self.headingCurrent = newheading
        headingUpdates.add_observation(Observation(v: newheading, t: Date()))
    }
    
    func setResponsiveness(_ index: Int) {
        responsivenessIndex = index
        headingUpdates.window_secs = resonsivenessWindowSecs()
    }
    
    func modifyTarget(_ delta: Double) {
        if headingTarget != nil {
            headingTarget = (headingTarget! + delta).truncatingRemainder(dividingBy: 360.0)
        }
    }
    
    //CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        updateCurrentHeading(newHeading.magneticHeading)
    }
    
    class func correctionDegrees(_ current: CLLocationDegrees, target: CLLocationDegrees) -> CLLocationDegrees {
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
