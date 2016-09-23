//
//  ObservationHistory.swift
//  VISCompass
//
//  Created by Matt Clark on 06/11/2015.
//  Copyright © 2015 mattclark.net. All rights reserved.
//

import Foundation
import CoreLocation


struct Observation {
    let v: Double
    let t: Date
}

class ObservationHistory {
    var deltaFunc: (Double, Double) -> Double = { (v1: Double, v2: Double) -> Double in return v1 - v2 }
    let gamma = 2.0
    var window_secs: Double = 10.0
    let interval = 1.0
    var otherObservations: [Observation] = []
    var mostRecentObservation: Observation?
    
    //
    // internal interface
    //
    
    init(deltaFunc f: @escaping (Double, Double) -> Double, window_secs: Double) {
        self.deltaFunc = f
        self.window_secs = window_secs
    }
    
    func add_observation(_ o: Observation) {
        var new_obs = observations() + [o]
        new_obs = new_obs.sorted(by: timesorted)
        mostRecentObservation = new_obs.removeFirst()
        otherObservations = new_obs.filter(usable)
    }
    
    func smoothed(_ reftime: Date) -> Double? {
        var iseries = interval_series(reftime)
        if iseries.count == 0 {
            return nil
        }
        var sv = iseries.removeFirst()
        for (i, v) in iseries.enumerated() {
            let delta_t = Double((i + 1)) * interval
            let delta_v = weight(delta_t) * deltaFunc(sv, v)
            sv = sv + delta_v
        }
        return sv
    }
    
    //
    // private interface
    //
    
    func observations() -> [Observation] {
        if mostRecentObservation == nil {
            return []
        }
        var obs = [mostRecentObservation!]
        obs += otherObservations
        return obs
    }
    
    fileprivate func usable(_ o: Observation) -> Bool {
        let window_start = Date().timeIntervalSinceReferenceDate - window_secs
        return o.t.timeIntervalSinceReferenceDate > window_start
    }
    
    fileprivate func timesorted(_ o1: Observation, o2: Observation) -> Bool {
        return o1.t.timeIntervalSinceReferenceDate > o2.t.timeIntervalSinceReferenceDate
    }
    
    func interval_series(_ reftime: Date) -> [Double] {
        // create a series of equally intervaled values from intermittent observations
        var s = [Double]()
        var t = reftime.timeIntervalSinceReferenceDate
        let earliest_t = t - window_secs
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

    fileprivate func weight(_ delta_t: Double) -> Double {
        if delta_t >= window_secs {
            return 0
        }
        let linear_weight = (window_secs - delta_t) / window_secs
        return pow(linear_weight, gamma)
    }
}
