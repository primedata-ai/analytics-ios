//
//  PDMiddleware.m
//  Analytics
//
//  Created by Tony Xiao on 9/19/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import "PDUtils.h"
#import "PDMiddleware.h"


@implementation PDDestinationMiddleware
- (instancetype)initWithKey:(NSString *)integrationKey middleware:(NSArray<id<PDMiddleware>> *)middleware
{
    if (self = [super init]) {
        _integrationKey = integrationKey;
        _middleware = middleware;
    }
    return self;
}
@end

@implementation PDBlockMiddleware

- (instancetype)initWithBlock:(PDMiddlewareBlock)block
{
    if (self = [super init]) {
        _block = block;
    }
    return self;
}

- (void)context:(PDContext *)context next:(PDMiddlewareNext)next
{
    self.block(context, next);
}

@end


@implementation PDMiddlewareRunner

- (instancetype)initWithMiddleware:(NSArray<id<PDMiddleware>> *_Nonnull)middlewares
{
    if (self = [super init]) {
        _middlewares = middlewares;
    }
    return self;
}

- (PDContext *)run:(PDContext *_Nonnull)context callback:(RunMiddlewaresCallback _Nullable)callback
{
    return [self runMiddlewares:self.middlewares context:context callback:callback];
}

// TODO: Maybe rename PDContext to PDEvent to be a bit more clear?
// We could also use some sanity check / other types of logging here.
- (PDContext *)runMiddlewares:(NSArray<id<PDMiddleware>> *_Nonnull)middlewares
               context:(PDContext *_Nonnull)context
              callback:(RunMiddlewaresCallback _Nullable)callback
{
    __block PDContext * _Nonnull result = context;

    BOOL earlyExit = context == nil;
    if (middlewares.count == 0 || earlyExit) {
        if (callback) {
            callback(earlyExit, middlewares);
        }
        return context;
    }
    
    [middlewares[0] context:result next:^(PDContext *_Nullable newContext) {
        NSArray *remainingMiddlewares = [middlewares subarrayWithRange:NSMakeRange(1, middlewares.count - 1)];
        result = [self runMiddlewares:remainingMiddlewares context:newContext callback:callback];
    }];
    
    return result;
}

@end
