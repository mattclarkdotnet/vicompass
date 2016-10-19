//
//  VISCompassTests.swift
//  VISCompassTests
//
//  Created by Matt Clark on 09/08/2015.
//  Copyright © 2015 mattclark.net. All rights reserved.
//

import XCTest
import CoreLocation

class VISCompassTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testCorrectionCalculation() {
        XCTAssertEqual(CompassModel.correctionDegrees(0, target: 0), 0)
        XCTAssertEqual(CompassModel.correctionDegrees(90, target: 90), 0)
        XCTAssertEqual(CompassModel.correctionDegrees(180, target: 180), 0)
        XCTAssertEqual(CompassModel.correctionDegrees(270, target: 270), 0)
        XCTAssertEqual(CompassModel.correctionDegrees(359, target: 359), 0)
        XCTAssertEqual(CompassModel.correctionDegrees(1, target: 1), 0)
        XCTAssertEqual(CompassModel.correctionDegrees(10, target: 20), 10)
        XCTAssertEqual(CompassModel.correctionDegrees(20, target: 10), -10)
        XCTAssertEqual(CompassModel.correctionDegrees(350, target: 20), 30)
        XCTAssertEqual(CompassModel.correctionDegrees(20, target: 350), -30)
        XCTAssertEqual(CompassModel.correctionDegrees(350, target: 320), -30)
        XCTAssertEqual(CompassModel.correctionDegrees(320, target: 350), 30)
        XCTAssertEqual(CompassModel.correctionDegrees(190, target: 0), 170)
        XCTAssertEqual(CompassModel.correctionDegrees(0, target: 190), -170)
        XCTAssertEqual(CompassModel.correctionDegrees(170, target: 190), 20)
        XCTAssertEqual(CompassModel.correctionDegrees(190, target: 170), -20)
        XCTAssertEqual(CompassModel.correctionDegrees(90, target: 270), 180)
        XCTAssertEqual(CompassModel.correctionDegrees(270, target: 90), 180)
    }
    
}

class ObservationTests: XCTestCase {
    func testOneObservation() {
        let now = Date()
        // If we have one observation within the window, then that is the only value in the interval series
        let oh = ObservationHistory(deltaFunc: CompassModel.correctionDegrees, window_secs: 10)
        oh.add_observation(Observation(v: 20, t: now))
        XCTAssertEqual(oh.interval_series(now), [20.0])
        XCTAssertEqual(oh.interval_series(Date(timeIntervalSinceReferenceDate: now.timeIntervalSinceReferenceDate + oh.interval)), [20.0, 20.0])
        XCTAssertEqual(oh.interval_series(Date(timeIntervalSinceReferenceDate: now.timeIntervalSinceReferenceDate + oh.interval * 2)), [20.0, 20.0, 20.0])
    }

    func testTwoObservations() {
        let now = Date()
        let oh = ObservationHistory(deltaFunc: CompassModel.correctionDegrees, window_secs: 10)
        let o1 = Observation(v: 20, t: Date(timeIntervalSinceReferenceDate: now.timeIntervalSinceReferenceDate - oh.interval))
        let o2 = Observation(v: 10, t: now)
        oh.add_observation(o1)
        oh.add_observation(o2)
        let obs = oh.observations()
        XCTAssertEqual(obs.count, 2)
        XCTAssertEqual(obs[0].v, o2.v)
        XCTAssertEqual(obs[1].v, o1.v)
        XCTAssertEqual(oh.interval_series(now), [10.0, 20.0])
        XCTAssertEqual(oh.interval_series(Date(timeIntervalSinceReferenceDate: now.timeIntervalSinceReferenceDate + oh.interval)), [10.0, 10.0, 20.0])
        XCTAssertEqual(oh.interval_series(Date(timeIntervalSinceReferenceDate: now.timeIntervalSinceReferenceDate + oh.interval * 2)), [10.0, 10.0, 10.0, 20.0])
    }
    
    func testThreeObservations() {
        let now = Date()
        let oh = ObservationHistory(deltaFunc: CompassModel.correctionDegrees, window_secs: 10)
        let o1 = Observation(v: 30, t: Date(timeIntervalSinceReferenceDate: now.timeIntervalSinceReferenceDate - oh.interval * 2))
        let o2 = Observation(v: 20, t: Date(timeIntervalSinceReferenceDate: now.timeIntervalSinceReferenceDate - oh.interval ))
        let o3 = Observation(v: 10, t: now)
        oh.add_observation(o1)
        oh.add_observation(o2)
        oh.add_observation(o3)
        let obs = oh.observations()
        XCTAssertEqual(obs.count, 3)
        XCTAssertEqual(obs[0].v, o3.v)
        XCTAssertEqual(obs[1].v, o2.v)
        XCTAssertEqual(obs[2].v, o1.v)
        XCTAssertEqual(oh.interval_series(now), [10.0, 20.0, 30.0])
        XCTAssertEqual(oh.interval_series(Date(timeIntervalSinceReferenceDate: now.timeIntervalSinceReferenceDate + oh.interval)), [10.0, 10.0, 20.0, 30.0])
        XCTAssertEqual(oh.interval_series(Date(timeIntervalSinceReferenceDate: now.timeIntervalSinceReferenceDate + oh.interval * 2)), [10.0, 10.0, 10.0, 20.0, 30.0])
    }
    
    func testSmoothing() {
        let now = Date()
        let oh = ObservationHistory(deltaFunc: CompassModel.correctionDegrees, window_secs: 10)
        let o1 = Observation(v: 20, t: Date(timeIntervalSinceReferenceDate: now.timeIntervalSinceReferenceDate - oh.interval))
        let o2 = Observation(v: 10, t: now)
        oh.add_observation(o1)
        oh.add_observation(o2)
        XCTAssertEqualWithAccuracy(oh.smoothed(now.addingTimeInterval(oh.window_secs * 2))!, 10, accuracy: 0.01)
        XCTAssertEqualWithAccuracy(oh.smoothed(now.addingTimeInterval(oh.window_secs))!, 10, accuracy: 0.01)
        XCTAssertEqualWithAccuracy(oh.smoothed(now.addingTimeInterval(oh.window_secs / 10))!, 16.4, accuracy: 0.01)
        XCTAssertEqualWithAccuracy(oh.smoothed(now.addingTimeInterval(oh.window_secs / 2))!, 11.6, accuracy: 0.01)
    }
}

