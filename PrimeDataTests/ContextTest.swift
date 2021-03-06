//
//  ContextTest.swift
//  Analytics
//
//  Created by Tony Xiao on 9/20/16.
//  Copyright © 2016 PrimeData. All rights reserved.
//

import PrimeData
import XCTest

class ContextTests: XCTestCase {
    
    var analytics: Analytics!
    
    override func setUp() {
        super.setUp()
        let config = AnalyticsConfiguration(writeKey: "QUI5ydwIGeFFTa1IvCBUhxL9PyW5B0jE", scopeKey:"IOS-bfiahefiohjsad0f0-9sdaujfd", url: "https://powehi.primedata.ai")
        analytics = Analytics(configuration: config)
    }
    
    func testThrowsWhenUsedIncorrectly() {
        var context: Context?
        var exception: NSException?
        
        exception = objc_tryCatch {
            context = Context()
        }
        
        XCTAssertNil(context)
        XCTAssertNotNil(exception)
    }
    
    func testInitializedCorrectly() {
        let context = Context(analytics: analytics)
        XCTAssertEqual(context._analytics, analytics)
        XCTAssertEqual(context.eventType, EventType.undefined)
    }
    
    func testAcceptsModifications() {
        let context = Context(analytics: analytics)
        
        let newContext = context.modify { context in
            context.payload = TrackPayload()
            context.payload?.userId = "sloth"
            context.eventType = .track
        }
        XCTAssertEqual(newContext.payload?.userId, "sloth")
        XCTAssertEqual(newContext.eventType,  EventType.track)
    }
    
    func testModifiesCopyInDebugMode() {
        let context = Context(analytics: analytics).modify { context in
            context.debug = true
            context.eventType = .track
        }
        XCTAssertEqual(context.debug, true)
        
        let newContext = context.modify { context in
            context.eventType = .identify
        }
        XCTAssertNotEqual(context, newContext)
        XCTAssertEqual(newContext.eventType, .identify)
        XCTAssertEqual(context.eventType, .track)
    }
    
    func testModifiesSelfInNonDebug() {
        let context = Context(analytics: analytics).modify { context in
            context.debug = false
            context.eventType = .track
        }
        XCTAssertFalse(context.debug)
        
        let newContext = context.modify { context in
            context.eventType = .identify
        }
        XCTAssertEqual(context, newContext)
        XCTAssertEqual(newContext.eventType, .identify)
        XCTAssertEqual(context.eventType, .identify)
    }
}
