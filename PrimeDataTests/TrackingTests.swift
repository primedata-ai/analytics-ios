//
//  TrackingTests.swift
//  Analytics
//
//  Created by Tony Xiao on 9/16/16.
//  Copyright © 2016 PrimeData. All rights reserved.
//


import PrimeData
import XCTest

class TrackingTests: XCTestCase {
    
    var passthrough: PassthroughMiddleware!
    var analytics: Analytics!
    
    override func setUp() {
        super.setUp()
        let config = AnalyticsConfiguration(writeKey: "QUI5ydwIGeFFTa1IvCBUhxL9PyW5B0jE", scopeKey:"IOS-bfiahefiohjsad0f0-9sdaujfd", url: "https://powehi.primedata.ai")
        config.flushAt = 1
        passthrough = PassthroughMiddleware()
        config.sourceMiddleware = [
            passthrough,
        ]
        analytics = Analytics(configuration: config)
    }
    
    override func tearDown() {
        super.tearDown()
        analytics.reset()
    }
    
    func testHandlesAlias() {
        analytics.alias("persistentUserId")
        XCTAssertEqual(passthrough.lastContext?.eventType, EventType.alias)
        let payload = passthrough.lastContext?.payload as? AliasPayload
        XCTAssertEqual(payload?.theNewId, "persistentUserId")
    }
    
    func testHandlesScreen() {
        analytics.screen("Home", category:"test", properties: [
            "referrer": "Google"
        ])
        XCTAssertEqual(passthrough.lastContext?.eventType, EventType.screen)
        let screen = passthrough.lastContext?.payload as? ScreenPayload
        XCTAssertEqual(screen?.name, "Home")
        XCTAssertEqual(screen?.category, "test")
        XCTAssertEqual(screen?.properties?["referrer"] as? String, "Google")
    }
    
    func testHandlesGroup() {
        analytics.group("acme-company", traits: [
            "employees": 2333
        ])
        XCTAssertEqual(passthrough.lastContext?.eventType, EventType.group)
        let payload = passthrough.lastContext?.payload as? GroupPayload
        XCTAssertEqual(payload?.groupId, "acme-company")
        XCTAssertEqual(payload?.traits?["employees"] as? Int, 2333)
    }
}
