//
//  StoreKitTrackerTest.swift
//  Analytics
//
//  Created by Tony Xiao on 9/20/16.
//  Copyright © 2016 PrimeData. All rights reserved.
//

import PrimeData
import XCTest

class mockTransaction: SKPaymentTransaction {
  override var transactionIdentifier: String? {
    return "tid"
  }
  override var transactionState: SKPaymentTransactionState {
    return SKPaymentTransactionState.purchased
  }
  override var payment: SKPayment {
    return mockPayment()
  }
}

class mockPayment: SKPayment {
  override var productIdentifier: String { return "pid" }
}

class mockProduct: SKProduct {
  override var productIdentifier: String { return "pid" }
  override var price: NSDecimalNumber { return 3 }
  override var localizedTitle: String { return "lt" }

}

class mockProductResponse: SKProductsResponse {
  override var products: [SKProduct] {
    return [mockProduct()]
  }
}

class StoreKitTrackerTests: XCTestCase {

    var test: TestMiddleware!
    var tracker: StoreKitTracker!
    var analytics: Analytics!
    
    override func setUp() {
        super.setUp()
        let config = AnalyticsConfiguration(writeKey: "QUI5ydwIGeFFTa1IvCBUhxL9PyW5B0jE", scopeKey:"IOS-bfiahefiohjsad0f0-9sdaujfd", url: "https://powehi.primedata.ai")
        test = TestMiddleware()
        config.sourceMiddleware = [test]
        analytics = Analytics(configuration: config)
        tracker = StoreKitTracker.trackTransactions(for: analytics)
    }
}
