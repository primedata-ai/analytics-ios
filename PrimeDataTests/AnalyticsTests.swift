//
//  AnalyticsTests.swift
//  Analytics
//
//  Created by Tony Xiao on 9/16/16.
//  Copyright © 2016 PrimeData. All rights reserved.
//


@testable import PrimeData
import XCTest

class AnalyticsTests: XCTestCase {
    
    let config = AnalyticsConfiguration(writeKey: "1klTIBeF4McXUFp2WySSjYtJroA", scopeKey:"IOS-1klTI9PsENXKu1Jt9zoS4A1OSUD", url: "https://powehi.primedata.ai")
    let cachedSettings = [
        "integrations": [
            "PrimeData.io": ["apiKey": "QUI5ydwIGeFFTa1IvCBUhxL9PyW5B0jE"]
        ],
        "plan": ["track": [:]],
        ] as NSDictionary

    var analytics: Analytics!
    var testMiddleware: TestMiddleware!
    var testApplication: TestApplication!
    
    override func setUp() {
        super.setUp()
        testMiddleware = TestMiddleware()
        config.sourceMiddleware = [testMiddleware]
        testApplication = TestApplication()
        config.application = testApplication
        config.trackApplicationLifecycleEvents = true
        
        UserDefaults.standard.set("test PDQueue should be removed", forKey: "PDQueue")
        // pump the run loop so we can be sure the value was written.
        RunLoop.current.run(until: Date.distantPast)
        XCTAssertNotNil(UserDefaults.standard.string(forKey: "PDQueue"))

        analytics = Analytics(configuration: config)
        analytics.test_integrationsManager()?.test_setCachedSettings(settings: cachedSettings)
    }
    
    override func tearDown() {
        super.tearDown()
        analytics.reset()
    }
    
    func testInitializedCorrectly() {
        
        XCTAssertEqual(config.flushAt, 20)
        XCTAssertEqual(config.flushInterval, 30)
        XCTAssertEqual(config.maxQueueSize, 1000)
        XCTAssertEqual(config.writeKey, "1klTIBeF4McXUFp2WySSjYtJroA")
        XCTAssertEqual(config.shouldUseLocationServices, false)
        XCTAssertEqual(config.enableAdvertisingTracking, true)
        XCTAssertEqual(config.shouldUseBluetooth,  false)
        XCTAssertNil(config.httpSessionDelegate)
        XCTAssertNotNil(analytics.getAnonymousId())
    }

    func testCreateNewSession() {
        config.createNewSession("IU9934325-34RFWESR-FDWRE-98REGU9")
        XCTAssertEqual(config.sessionId, "IU9934325-34RFWESR-FDWRE-98REGU9")
    }
    
    func testIdentify() {
        analytics.identify("peternguyen")
        analytics.identify("peternguyen", email: "peternguyen@gmail.com")
    }
    
    func testWebhookIntegrationInitializedCorrectly() {
        let webhookIntegration = WebhookIntegrationFactory.init(name: "dest1", webhookUrl: "blah")
        let webhookIntegrationKey = webhookIntegration.key()
        var initialized = false
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: PDAnalyticsIntegrationDidStart), object: nil, queue: nil) { (notification) in
            let key = notification.object as? String
            if (key == webhookIntegrationKey) {
                initialized = true
            }
        }
        let config2 = AnalyticsConfiguration(writeKey: "TESTKEY", scopeKey:"IOS-bfiahefiohjsad0f0-9sdaujfd" , url: "https://testurl.com")
        config2.use(webhookIntegration)
        let analytics2 = Analytics(configuration: config2)
        let factoryList = (config2.value(forKey: "factories") as? NSMutableArray)
        XCTAssertEqual(factoryList?.count, 1)

        while (!initialized) { // wait for WebhookIntegration to get setup
            sleep(1)
        }
        XCTAssertNotNil(analytics2.test_integrationsManager()?.test_integrations()?[webhookIntegrationKey])
    }
    
    func testClearsPDQueueFromUserDefaults() {
        expectUntil(2.0, expression: UserDefaults.standard.string(forKey: "PDQueue") == nil)
    }
    
    /* TODO: Fix me when the Context object isn't so wild.
     func testCollectsIDFA() {
     testMiddleware.swallowEvent = true
     analytics.configuration.enableAdvertisingTracking = true
     analytics.configuration.adSupportBlock = { () -> String in
     return "1234AdsNoMore!"
     }
     
     analytics.track("test");
     
     let event = testMiddleware.lastContext?.payload as? TrackPayload
     XCTAssertEqual(event?.properties?["url"] as? String, "myapp://auth?token=((redacted/my-auth))&other=stuff")
     }*/
    
    func testPersistsAnonymousId() {
        let analytics2 = Analytics(configuration: config)
        XCTAssertEqual(analytics.getAnonymousId(), analytics2.getAnonymousId())
    }
    
    func testFiresApplicationDuringEnterBackground() {
        testMiddleware.swallowEvent = true
        #if os(macOS)
        NotificationCenter.default.post(name: NSApplication.didResignActiveNotification, object: testApplication)
        #else
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: testApplication)
        #endif
        let event = testMiddleware.lastContext?.payload as? TrackPayload
        XCTAssertEqual(event?.event, "Application Closed")
    }
    
    func testRespectsMaxQueueSize() {
        let max = 72
        config.maxQueueSize = UInt(max)
        
        for i in 1...max * 2 {
            analytics.track("test #\(i)")
        }
        
        let integration = analytics.test_integrationsManager()?.test_segmentIntegration()
        XCTAssertNotNil(integration)
        
        analytics.flush()
        let currentTime = Date()
        while(integration?.test_queue()?.count != max && currentTime < currentTime + 60) {
            sleep(1)
        }
    }
    
    #if !os(macOS)
    func testProtocolConformanceShouldNotInterfere() {
        // In Xcode8/iOS10, UIApplication.h typedefs UIBackgroundTaskIdentifier as NSUInteger,
        // whereas Swift has UIBackgroundTaskIdentifier typealiaed to Int.
        // This is likely due to a custom Swift mapping for UIApplication which got out of sync.
        // If we extract the exact UIApplication method names in PDApplicationProtocol,
        // it will cause a type mismatch between the return value from beginBackgroundTask
        // and the argument for endBackgroundTask.
        // This would impact all code in a project that imports the PrimeData framework.
        // Note that this doesn't appear to be an issue any longer in Xcode9b3.
        let task = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        UIApplication.shared.endBackgroundTask(task)
    }
    #endif
    
    func testRespectsFlushIntervale() {
        let timer = analytics
            .test_integrationsManager()?
            .test_segmentIntegration()?
            .test_flushTimer()
        
        XCTAssertNotNil(timer)
        XCTAssertEqual(timer?.timeInterval, config.flushInterval)
    }
    
    func testDeviceTokenRegistration() {
        func getStringFrom(token: Data) -> String {
            return token.reduce("") { $0 + String(format: "%02.2hhx", $1) }
        }
        
        let deviceToken = GenerateUUIDString()
        let data = deviceToken.data(using: .utf8)
        if let data = data {
            analytics.registeredForRemoteNotifications(withDeviceToken: data)
            let deviceTokenString = getStringFrom(token: data)
            XCTAssertTrue(deviceTokenString == analytics.getDeviceToken())

        } else {
            XCTAssertNotNil(data)
        }
    }
}
