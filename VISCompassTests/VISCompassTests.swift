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
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testCorrectionCalculation() {
        XCTAssertEqual(ViewController.calcCorrection(0, target: 0), 0)
        XCTAssertEqual(ViewController.calcCorrection(90, target: 90), 0)
        XCTAssertEqual(ViewController.calcCorrection(180, target: 180), 0)
        XCTAssertEqual(ViewController.calcCorrection(270, target: 270), 0)
        XCTAssertEqual(ViewController.calcCorrection(359, target: 359), 0)
        XCTAssertEqual(ViewController.calcCorrection(1, target: 1), 0)
        XCTAssertEqual(ViewController.calcCorrection(10, target: 20), 10)
        XCTAssertEqual(ViewController.calcCorrection(20, target: 10), -10)
        XCTAssertEqual(ViewController.calcCorrection(350, target: 20), 30)
        XCTAssertEqual(ViewController.calcCorrection(20, target: 350), -30)
        XCTAssertEqual(ViewController.calcCorrection(350, target: 320), -30)
        XCTAssertEqual(ViewController.calcCorrection(320, target: 350), 30)
        XCTAssertEqual(ViewController.calcCorrection(190, target: 0), 170)
        XCTAssertEqual(ViewController.calcCorrection(0, target: 190), -170)
        XCTAssertEqual(ViewController.calcCorrection(170, target: 190), 20)
        XCTAssertEqual(ViewController.calcCorrection(190, target: 170), -20)
        XCTAssertEqual(ViewController.calcCorrection(90, target: 270), 180)
        XCTAssertEqual(ViewController.calcCorrection(270, target: 90), 180)
    }
    
    func testCorrectionUIColor() {
        XCTAssertEqual(ViewController.correctionUIColor(0, tolerance: 5), UIColor.whiteColor())
        XCTAssertEqual(ViewController.correctionUIColor(5, tolerance: 5), UIColor.whiteColor())
        XCTAssertEqual(ViewController.correctionUIColor(-5, tolerance: 5), UIColor.whiteColor())
        XCTAssertEqual(ViewController.correctionUIColor(5, tolerance: 4), UIColor.greenColor())
        XCTAssertEqual(ViewController.correctionUIColor(-5, tolerance: 4), UIColor.redColor())
    }
    
    func testBeepInterval() {
        let vc = ViewController()
        vc.setBeepInterval(5)
        XCTAssertEqual(vc.beepInterval, 2)
        vc.setBeepInterval(-5)
        XCTAssertEqual(vc.beepInterval, 2)
    }
}

class ObservationTests: XCTestCase {
    func testOneObservation() {
        let now = NSDate()
        // If we have one observation within the window, then that is the only value in the interval series
        let oh = ObservationHistory(deltaFunc: ViewController.calcCorrection, window_secs: 10)
        oh.add_observation(Observation(v: 20, t: now))
        XCTAssertEqual(oh.interval_series(now), [20.0])
        XCTAssertEqual(oh.interval_series(NSDate(timeIntervalSinceReferenceDate: now.timeIntervalSinceReferenceDate + oh.interval)), [20.0, 20.0])
        XCTAssertEqual(oh.interval_series(NSDate(timeIntervalSinceReferenceDate: now.timeIntervalSinceReferenceDate + oh.interval * 2)), [20.0, 20.0, 20.0])
    }

    func testTwoObservations() {
        let now = NSDate()
        let oh = ObservationHistory(deltaFunc: ViewController.calcCorrection, window_secs: 10)
        let o1 = Observation(v: 20, t: NSDate(timeIntervalSinceReferenceDate: now.timeIntervalSinceReferenceDate - oh.interval))
        let o2 = Observation(v: 10, t: now)
        oh.add_observation(o1)
        oh.add_observation(o2)
        let obs = oh.observations()
        XCTAssertEqual(obs.count, 2)
        XCTAssertEqual(obs[0].v, o2.v)
        XCTAssertEqual(obs[1].v, o1.v)
        XCTAssertEqual(oh.interval_series(now), [10.0, 20.0])
        XCTAssertEqual(oh.interval_series(NSDate(timeIntervalSinceReferenceDate: now.timeIntervalSinceReferenceDate + oh.interval)), [10.0, 10.0, 20.0])
        XCTAssertEqual(oh.interval_series(NSDate(timeIntervalSinceReferenceDate: now.timeIntervalSinceReferenceDate + oh.interval * 2)), [10.0, 10.0, 10.0, 20.0])
    }
    
    func testThreeObservations() {
        let now = NSDate()
        let oh = ObservationHistory(deltaFunc: ViewController.calcCorrection, window_secs: 10)
        let o1 = Observation(v: 30, t: NSDate(timeIntervalSinceReferenceDate: now.timeIntervalSinceReferenceDate - oh.interval * 2))
        let o2 = Observation(v: 20, t: NSDate(timeIntervalSinceReferenceDate: now.timeIntervalSinceReferenceDate - oh.interval ))
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
        XCTAssertEqual(oh.interval_series(NSDate(timeIntervalSinceReferenceDate: now.timeIntervalSinceReferenceDate + oh.interval)), [10.0, 10.0, 20.0, 30.0])
        XCTAssertEqual(oh.interval_series(NSDate(timeIntervalSinceReferenceDate: now.timeIntervalSinceReferenceDate + oh.interval * 2)), [10.0, 10.0, 10.0, 20.0, 30.0])
    }
    
    func testSmoothing() {
        let now = NSDate()
        let oh = ObservationHistory(deltaFunc: ViewController.calcCorrection, window_secs: 10)
        let o1 = Observation(v: 20, t: NSDate(timeIntervalSinceReferenceDate: now.timeIntervalSinceReferenceDate - oh.interval))
        let o2 = Observation(v: 10, t: now)
        oh.add_observation(o1)
        oh.add_observation(o2)
        XCTAssertEqualWithAccuracy(oh.smoothed(now.dateByAddingTimeInterval(oh.window_secs * 2))!, 10, accuracy: 0.01)
        XCTAssertEqualWithAccuracy(oh.smoothed(now.dateByAddingTimeInterval(oh.window_secs))!, 10, accuracy: 0.01)
        XCTAssertEqualWithAccuracy(oh.smoothed(now.dateByAddingTimeInterval(oh.window_secs / 10))!, 16.4, accuracy: 0.01)
        XCTAssertEqualWithAccuracy(oh.smoothed(now.dateByAddingTimeInterval(oh.window_secs / 2))!, 11.6, accuracy: 0.01)
    }
}

