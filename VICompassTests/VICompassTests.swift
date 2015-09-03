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
    
    func testCorrectionCalculation() {
        let vc = ViewController()
        XCTAssertEqual(vc.calcCorrection(10, target: nil), nil)
        XCTAssertEqual(vc.calcCorrection(0, target: 0), 0)
        XCTAssertEqual(vc.calcCorrection(180, target: 180), 0)
        XCTAssertEqual(vc.calcCorrection(359, target: 359), 0)
        XCTAssertEqual(vc.calcCorrection(180, target: 180), 0)
        XCTAssertEqual(vc.calcCorrection(10, target: 20), 10)
        XCTAssertEqual(vc.calcCorrection(20, target: 10), -10)
        XCTAssertEqual(vc.calcCorrection(350, target: 20), 30)
        XCTAssertEqual(vc.calcCorrection(20, target: 350), -30)
        XCTAssertEqual(vc.calcCorrection(190, target: 0), 170)
        XCTAssertEqual(vc.calcCorrection(0, target: 190), -170)
        XCTAssertEqual(vc.calcCorrection(170, target: 190), 20)
        XCTAssertEqual(vc.calcCorrection(190, target: 170), -20)
        XCTAssertEqual(vc.calcCorrection(90, target: 270), 180)
        XCTAssertEqual(vc.calcCorrection(270, target: 90), 180)
    }
    
    func testCorrectionUIColor() {
        let vc = ViewController()
        XCTAssertEqual(vc.correctionUIColor(0, tolerance: 5), UIColor.whiteColor())
        XCTAssertEqual(vc.correctionUIColor(5, tolerance: 5), UIColor.whiteColor())
        XCTAssertEqual(vc.correctionUIColor(-5, tolerance: 5), UIColor.whiteColor())
        XCTAssertEqual(vc.correctionUIColor(5, tolerance: 4), UIColor.greenColor())
        XCTAssertEqual(vc.correctionUIColor(-5, tolerance: 4), UIColor.redColor())
    }
    
    func testBeepInterval() {
        let vc = ViewController()
        XCTAssertEqual(vc.beepInterval(5), 2)
        XCTAssertEqual(vc.beepInterval(-5), 2)
    }
    
}
