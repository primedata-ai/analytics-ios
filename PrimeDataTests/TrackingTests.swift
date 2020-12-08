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
        let config = AnalyticsConfiguration(writeKey: "1klTIBeF4McXUFp2WySSjYtJroA", scopeKey:"IOS-1klTI9PsENXKu1Jt9zoS4A1OSUD", url: "https://powehi.primedata.ai")
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

    func testTrackEventWithEventName() {
        analytics.track("open_app")
        XCTAssertEqual(passthrough.lastContext?.eventType, EventType.track)
        let payload = passthrough.lastContext?.payload as? TrackPayload
        XCTAssertEqual(payload?.event, "open_app")
    }
    
    func testTrackEventWithPropertiesSourceTarget() {
        analytics.track("category_viewed_test", properties:["category_id": "SALE_OFF","category_level": "50_PERCENT_OFF","category_name": "BEAT THE CHILL KNITS & JACKETS","category_url_slug": "JUST_ARRVED_TAB"], source: ["itemId": "ARRVED","itemType": "ARRVED_TAB"], target: ["itemId": "ARRVED_TAB_ROW","itemType": "ARRVED_TAB_ROW"])
        XCTAssertEqual(passthrough.lastContext?.eventType, EventType.track)
        let payload = passthrough.lastContext?.payload as? TrackPayload
        XCTAssertEqual(payload?.event, "category_viewed_test")
    }
    
    func testTrackEventWithPropertiesSourceTargetNULL() {
        analytics.track("category_viewed_test", properties:nil, source: nil, target: nil)
        XCTAssertEqual(passthrough.lastContext?.eventType, EventType.track)
        let payload = passthrough.lastContext?.payload as? TrackPayload
        XCTAssertEqual(payload?.event, "category_viewed_test")
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
