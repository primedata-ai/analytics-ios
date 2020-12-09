# Analytics
[![Circle CI](https://circleci.com/gh/segmentio/analytics-ios.svg?style=shield&circle-token=31c5b3e5edeb404b30141ead9dcef3eb37d16d4d)](https://circleci.com/gh/segmentio/analytics-ios)
[![Version](https://img.shields.io/cocoapods/v/Analytics.svg?style=flat)](https://cocoapods.org//pods/Analytics)
[![License](https://img.shields.io/cocoapods/l/Analytics.svg?style=flat)](http://cocoapods.org/pods/Analytics)
[![codecov](https://codecov.io/gh/segmentio/analytics-ios/branch/master/graph/badge.svg)](https://codecov.io/gh/segmentio/analytics-ios)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![SwiftPM Compatible](https://img.shields.io/badge/SwiftPM-Compatible-F05138.svg)](https://swift.org/package-manager/)

analytics-ios is an iOS client for PrimeData.

Special thanks to [Tony Xiao](https://github.com/tonyxiao), [Lee Hasiuk](https://github.com/lhasiuk) and [Cristian Bica](https://github.com/cristianbica) for their contributions to the library!

<div align="center">
  <img src="https://user-images.githubusercontent.com/16131737/53752615-e66b8000-3e63-11e9-98f6-f478c7076537.png"/>
  <p><b><i>You can't fix what you can't measure</i></b></p>
</div>

Analytics helps you measure your users, product, and business. It unlocks insights into your app's funnel, core business metrics, and whether you have product-market fit.

## How to get started
1. **Collect analytics data** from your app(s).
    - The top 200 PrimeData companies collect data from 5+ source types (web, mobile, server, CRM, etc.).
2. **Send the data to analytics tools** (for example, Google Analytics, Amplitude, Mixpanel).
    - Over 250+ PrimeData companies send data to eight categories of destinations such as analytics tools, warehouses, email marketing and remarketing systems, session recording, and more.
3. **Explore your data** by creating metrics (for example, new signups, retention cohorts, and revenue generation).
    - The best PrimeData companies use retention cohorts to measure product market fit. Netflix has 70% paid retention after 12 months, 30% after 7 years.

[PrimeData](https://segment.com) collects analytics data and allows you to send it to more than 250 apps (such as Google Analytics, Mixpanel, Optimizely, Facebook Ads, Slack, Sentry) just by flipping a switch. You only need one PrimeData code snippet, and you can turn integrations on and off at will, with no additional code. [Sign up with PrimeData today](https://app.segment.com/signup).

### Why?
1. **Power all your analytics apps with the same data**. Instead of writing code to integrate all of your tools individually, send data to PrimeData, once.

2. **Install tracking for the last time**. We're the last integration you'll ever need to write. You only need to instrument PrimeData once. Reduce all of your tracking code and advertising tags into a single set of API calls.

3. **Send data from anywhere**. Send PrimeData data from any device, and we'll transform and send it on to any tool.

4. **Query your data in SQL**. Slice, dice, and analyze your data in detail with PrimeData SQL. We'll transform and load your customer behavioral data directly from your apps into Amazon Redshift, Google BigQuery, or Postgres. Save weeks of engineering time by not having to invent your own data warehouse and ETL pipeline.

    For example, you can capture data on any app:
    ```js
    analytics.track('Order Completed', { price: 99.84 })
    ```
    Then, query the resulting data in SQL:
    ```sql
    select * from app.order_completed
    order by price desc
    ```

### 🚀 Startup Program
<div align="center">
  <a href="https://segment.com/startups"><img src="https://user-images.githubusercontent.com/16131737/53128952-08d3d400-351b-11e9-9730-7da35adda781.png" /></a>
</div>
If you are part of a new startup  (&lt;$5M raised, &lt;2 years since founding), we just launched a new startup program for you. You can get a PrimeData Team plan  (up to <b>$25,000 value</b> in PrimeData credits) for free up to 2 years — <a href="https://segment.com/startups/">apply here</a>!

## Installation

Install Analytics using pod command.

### CocoaPods

```ruby
pod 'Analytics', :git => 'https://github.com/primedata-ai/analytics-ios.git'
```


## Quickstart

## Import SDK:  (Inside the Application Delegate Class)
```objective-c
#import <PrimeData.h>
```



## Initialize SDK: (Initialize SDK inside the - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions )
```objective-c
PDAnalyticsConfiguration *configuration = [PDAnalyticsConfiguration configurationWithWriteKey: <write_key> scopeKey: <scope_key> url: <prime_data_server_url>];
[PDAnalytics setupWithConfiguration:configuration];
```

## Initialize SDK and change session timeout (in minutes, default value is 30 minutes)
```objective-c
PDAnalyticsConfiguration *configuration = [PDAnalyticsConfiguration configurationWithWriteKey: <write_key> scopeKey: <scope_key> url: <prime_data_server_url>];
configuration.sessionTimeout = <integer_number>;
[PDAnalytics setupWithConfiguration:configuration];
```

## Initialize SDK and change session timeout (in minutes, default value is 30 minutes) and change the number of events to send to server (default value is 20 events)
```objective-c
PDAnalyticsConfiguration *configuration = [PDAnalyticsConfiguration configurationWithWriteKey: <write_key> scopeKey: <scope_key> url: <prime_data_server_url>];
configuration.sessionTimeout = <integer_number>;
configuration.flushAt = <integer_number>;
[PDAnalytics setupWithConfiguration:configuration];
```
## Initialize SDK and enable AdSupport (purpose to get advertisingIdentifier)
```objective-c
PDAnalyticsConfiguration *configuration = [PDAnalyticsConfiguration configurationWithWriteKey: <write_key> scopeKey: <scope_key> url: <prime_data_server_url>];
configuration.sessionTimeout = <integer_number>;
configuration.flushAt = <integer_number>;
configuration.adSupportBlock = ^NSString * _Nonnull{
        return [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    };
[PDAnalytics setupWithConfiguration:configuration];
```

## Identify User:
```objective-c
[[PDAnalytics sharedAnalytics] identify: <user_id>];
[[PDAnalytics sharedAnalytics] identify: <user_id> email: <email>];
```

For examples:
```objective-c
[[PDAnalytics sharedAnalytics] identify:@"abc" email:@"abc@icloud.com"];
```

## Track events:
```objective-c
[[PDAnalytics sharedAnalytics] track: <event_name>];
[[PDAnalytics sharedAnalytics] track: <event_name>  properties: <NSDictionary> source: <NSDictionary>  target: <NSDictionary>];
```

For examples:
```objective-c
 [[PDAnalytics sharedAnalytics] track:@"category_viewed_test"
                              properties: @{
                                              @"category_id": @"SALE_OFF",
                                              @"category_level": @"50_PERCENT_OFF",
                                              @"category_name": @"BEAT THE CHILL KNITS & JACKETS",
                                              @"category_url_slug": @"JUST_ARRVED_TAB"
                                          }
                                  source:@{
                                              @"itemId": @"ARRVED",
                                              @"itemType": @"ARRVED_TAB"
                                          }
                                  target: @{
                                               @"itemId": @"ARRVED_TAB_ROW",
                                               @"itemType": @"ARRVED_TAB_ROW"
                                           }];
//========================================================================================================
[[PDAnalytics sharedAnalytics] track:@"product_cart_dded_test"
                              properties: @{
                                             @"currency": @"Euro",
                                              @"product_category": [NSString stringWithFormat:@"%d", [productVariant.category intValue]],
                                              @"product_color": productVariant.color.name,
                                              @"product_id": [NSString stringWithFormat:@"%d", [productVariant.product.productID  intValue]],
                                              @"product_name": productVariant.product.name,
                                              @"product_price": [NSString stringWithFormat:@"%d", [productVariant.product.price intValue]]
                                          }
                                  source:@{
                                              @"itemId": @"SALE_OFF",
                                              @"itemType": @"BEAT THE CHILL KNITS & JACKETS"
                                          }
                                  target: @{
                                              @"itemId": productVariant.product.name,
                                              @"itemType": productVariant.product.name
                                           }]; 
```


