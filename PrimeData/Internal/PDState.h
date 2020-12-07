//
//  PDState.h
//  Analytics
//
//  Created by Brandon Sneed on 6/9/20.
//  Copyright © 2020 PrimeData. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PDAnalyticsConfiguration;

@interface PDUserInfo: NSObject
@property (nonatomic, strong) NSString *anonymousId;
@property (nonatomic, strong, nullable) NSString *userId;
@property (nonatomic, strong, nullable) NSDictionary *traits;
@end

@interface PDPayloadContext: NSObject
@property (nonatomic, readonly) NSDictionary *payload;
@property (nonatomic, strong, nullable) NSDictionary *referrer;
@property (nonatomic, strong, nullable) NSString *deviceToken;

- (void)updateStaticContext;

@end



@interface PDState : NSObject

@property (nonatomic, readonly) PDUserInfo *userInfo;
@property (nonatomic, readonly) PDPayloadContext *context;

@property (nonatomic, strong, nullable) PDAnalyticsConfiguration *configuration;

+ (instancetype)sharedInstance;
- (instancetype)init __unavailable;

- (void)setUserInfo:(PDUserInfo *)userInfo;
@end

NS_ASSUME_NONNULL_END
