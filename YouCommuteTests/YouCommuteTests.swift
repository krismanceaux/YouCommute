//
//  YouCommuteTests.swift
//  YouCommuteTests
//
//  Created by Kristopher Manceaux on 10/20/19.
//  Copyright © 2019 Kristopher Manceaux. All rights reserved.
//

import XCTest
@testable import YouCommute

class YouCommuteTests: XCTestCase {

    var eventDetailVC: EventDetailsViewController!
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        eventDetailVC = EventDetailsViewController()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        eventDetailVC = nil
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let seconds = 5000.00
        let formattedTime = eventDetailVC.formatTravelTime(timeInSeconds: seconds)
        XCTAssert(formattedTime == (1, 23, 20))
        
        
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
