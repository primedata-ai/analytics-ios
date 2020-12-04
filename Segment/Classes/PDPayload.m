#import "PDPayload.h"
#import "PDState.h"

@implementation PDPayload

@synthesize userId = _userId;
@synthesize anonymousId = _anonymousId;

- (instancetype)initWithContext:(NSDictionary *)context integrations:(NSDictionary *)integrations
{
    if (self = [super init]) {
        // combine existing state with user supplied context.
        NSDictionary *internalContext = [PDState sharedInstance].context.payload;
        
        NSMutableDictionary *combinedContext = [[NSMutableDictionary alloc] init];
        [combinedContext addEntriesFromDictionary:internalContext];
        [combinedContext addEntriesFromDictionary:context];

        _context = [combinedContext copy];
        _integrations = [integrations copy];
        _messageId = nil;
        _userId = nil;
        _anonymousId = nil;
    }
    return self;
}

@end


@implementation PDApplicationLifecyclePayload
@end


@implementation PDRemoteNotificationPayload
@end


@implementation PDContinueUserActivityPayload
@end


@implementation PDOpenURLPayload
@end
