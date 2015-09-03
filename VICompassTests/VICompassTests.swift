//
//  VICompassTests.swift
//  VICompassTests
//
//  Created by Matt Clark on 09/08/2015.
//  Copyright © 2015 mattclark.net. All rights reserved.
//

import XCTest

class VICompassTests: XCTestCase {
    
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
    
    func testDifferenceCalculation() {
        XCTAssertEqual(calcDifference(10, target: nil), nil)
        XCTAssertEqual(calcDifference(10, target: 10), 0)
        XCTAssertEqual(calcDifference(180, target: 180), 0)
        XCTAssertEqual(calcDifference(10, target: 20), -10)
        XCTAssertEqual(calcDifference(20, target: 10), 10)
        XCTAssertEqual(calcDifference(350, target: 20), -30)
        XCTAssertEqual(calcDifference(20, target: 350), 30)
        XCTAssertEqual(calcDifference(190, target: 0), -170)
        XCTAssertEqual(calcDifference(0, target: 190), 170)
        XCTAssertEqual(calcDifference(170, target: 190), -20)
        XCTAssertEqual(calcDifference(190, target: 170), 20)
        XCTAssertEqual(calcDifference(90, target: 270), 180)
        XCTAssertEqual(calcDifference(270, target: 90), 180)
    }
    
}
