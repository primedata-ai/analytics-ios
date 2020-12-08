@testable import PrimeData
import XCTest

class EndToEndTests: XCTestCase {
    
    var analytics: Analytics!
    var configuration: AnalyticsConfiguration!
    
    override func setUp() {
        super.setUp()
        
        // Write Key for https://app.segment.com/segment-libraries/sources/analytics_ios_e2e_test/overview
        configuration = AnalyticsConfiguration(writeKey: "QUI5ydwIGeFFTa1IvCBUhxL9PyW5B0jE", scopeKey:"IOS-bfiahefiohjsad0f0-9sdaujfd", url: "https://powehi.primedata.ai")
        configuration.flushAt = 1

        Analytics.setup(with: configuration)

        analytics = Analytics.shared()
    }
    
    override func tearDown() {
        super.tearDown()
        
        analytics.reset()
    }
}
