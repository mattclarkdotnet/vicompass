//
//  ObservationHistory.swift
//  VICompass
//
//  Created by Matt Clark on 06/11/2015.
//  Copyright © 2015 mattclark.net. All rights reserved.
//

import Foundation
import CoreLocation


struct Observation {
    let v: Double
    let t: NSDate
}

class ObservationHistory {
    var deltaFunc: (Double, Double) -> Double = { (v1: Double, v2: Double) -> Double in return v1 - v2 }
    let gamma = 2.0
    let window = 10.0
    let interval = 1.0
    var otherObservations: [Observation] = []
    var mostRecentObservation: Observation?
    
    init(deltaFunc f: (Double, Double) -> Double) {
        self.deltaFunc = f
    }
    
    func add_observation(o: Observation) {
        var new_obs = observations() + [o]
        new_obs = new_obs.sort(timesorted)
        mostRecentObservation = new_obs.removeFirst()
        otherObservations = new_obs.filter(usable)
    }
    
    func observations() -> [Observation] {
        if mostRecentObservation == nil {
            return []
        }
        var obs = [mostRecentObservation!]
        obs += otherObservations
        return obs
    }
    
    func usable(o: Observation) -> Bool {
        let window_start = NSDate().timeIntervalSinceReferenceDate - window
        return o.t.timeIntervalSinceReferenceDate > window_start
    }
    
    func timesorted(o1: Observation, o2: Observation) -> Bool {
        return o1.t.timeIntervalSinceReferenceDate > o2.t.timeIntervalSinceReferenceDate
    }
    
    func interval_series(reftime: NSDate) -> [Double] {
        // create a series of equally intervaled values from intermittent observations
        var s = [Double]()
        var t = reftime.timeIntervalSinceReferenceDate
        let earliest_t = t - window
        for o in observations() {
            while t >= o.t.timeIntervalSinceReferenceDate && t > earliest_t {
                s.append(o.v)
                t -= interval
            }
            if t < earliest_t {
                // the time is outside the window
                break
            }
        }
        return s
    }

    func weight(delta_t: Double) -> Double {
        if delta_t >= window {
            return 0
        }
        let linear_weight = (window - delta_t) / window
        return pow(linear_weight, gamma)
    }

    func smoothed(reftime: NSDate) -> Double? {
        var iseries = interval_series(reftime)
        if iseries.count == 0 {
            return nil
        }
        var sv = iseries.removeFirst()
        for (i, v) in iseries.enumerate() {
            let delta_t = Double((i + 1)) * interval
            let delta_v = weight(delta_t) * deltaFunc(sv, v)
            sv = sv + delta_v
        }
        return sv
    }
}
