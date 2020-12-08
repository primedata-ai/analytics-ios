//
//  MiddlewareTests.swift
//  Analytics
//
//  Created by Tony Xiao on 1/9/17.
//  Copyright © 2017 PrimeData. All rights reserved.
//


import PrimeData
import XCTest

// Changing event names and adding custom attributes
let customizeAllTrackCalls = BlockMiddleware { (context, next) in
    if context.eventType == .track {
        next(context.modify { ctx in
            guard let track = ctx.payload as? TrackPayload else {
                return
            }
            let newEvent = "[New] \(track.event)"
            var newProps = track.properties ?? [:]
            newProps["customAttribute"] = "Hello"
            newProps["nullTest"] = NSNull()
          
        })
    } else {
        next(context)
    }
}

// Simply swallows all calls and does not pass events downstream
let eatAllCalls = BlockMiddleware { (context, next) in
}

class SourceMiddlewareTests: XCTestCase {
    
    func testExpectsEventToBeSwallowed() {
        let config = AnalyticsConfiguration(writeKey: "QUI5ydwIGeFFTa1IvCBUhxL9PyW5B0jE", scopeKey:"IOS-bfiahefiohjsad0f0-9sdaujfd", url: "https://powehi.primedata.ai")
        let passthrough = PassthroughMiddleware()
        config.sourceMiddleware = [
            eatAllCalls,
            passthrough,
        ]
        let analytics = Analytics(configuration: config)
        analytics.track("Purchase Success")
        XCTAssertNil(passthrough.lastContext)
    }
}

class IntegrationMiddlewareTests: XCTestCase {
    
    func testExpectsEventToBeSwallowedIfOtherIsNotCalled() {
        // Since we're testing that an event is dropped, the previously used run loop pump won't work here.
        var initialized = false
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: PDAnalyticsIntegrationDidStart), object: nil, queue: nil) { (notification) in
            initialized = true
        }
        
        let config = AnalyticsConfiguration(writeKey: "QUI5ydwIGeFFTa1IvCBUhxL9PyW5B0jE", scopeKey:"IOS-bfiahefiohjsad0f0-9sdaujfd", url: "https://powehi.primedata.ai")
        let passthrough = PassthroughMiddleware()
        config.destinationMiddleware = [DestinationMiddleware(key: PrimeDataIntegrationFactory().key(), middleware: [eatAllCalls, passthrough])]
        let analytics = Analytics(configuration: config)
        analytics.track("Purchase Success")
        
        while (!initialized) {
            sleep(1)
        }
        
        XCTAssertNil(passthrough.lastContext)
    }
}
