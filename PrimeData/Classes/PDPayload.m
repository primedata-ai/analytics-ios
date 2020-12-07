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

        
        _pd_properties = nil;
        _pd_source = nil;
        _pd_target = nil;
        
        _context = [combinedContext copy];
        _integrations = [integrations copy];
        _messageId = nil;
        _userId = nil;
        _anonymousId = nil;
    }
    return self;
}

- (instancetype)initWithProperties:(JSON_DICT)properties source:(JSON_DICT)source target:(JSON_DICT)target context:(JSON_DICT)context integrations:(JSON_DICT)integrations
{
    if (self = [super init]) {
        // combine existing state with user supplied context.
        NSDictionary *internalContext = [PDState sharedInstance].context.payload;
        
        NSMutableDictionary *combinedContext = [[NSMutableDictionary alloc] init];
        [combinedContext addEntriesFromDictionary:internalContext];
        [combinedContext addEntriesFromDictionary:context];

        _pd_properties = [properties copy];
        _pd_source = [source copy];
        _pd_target = [target copy];
        
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

@implementation PDInitializePayload

- (instancetype)initWithEvent:(NSString*)event properties:(JSON_DICT)properties source:(JSON_DICT)source target:(JSON_DICT)target context:(JSON_DICT)context integrations:(JSON_DICT)integrations
{
    if (self = [super initWithProperties:properties source:source target:target context:context integrations:integrations]) {
        
        NSDictionary *internal_source = [PDState sharedInstance].context.payload;
        
        NSMutableDictionary *combined_source = [[NSMutableDictionary alloc] init];
        [combined_source addEntriesFromDictionary:internal_source];
        NSDictionary *dic =  @{
                      @"itemId": @"home",
                      @"itemType": @"screen",
                      @"properties": @{
                          @"screen_width": [NSString stringWithFormat:@"%d", [[[internal_source objectForKey:@"screen"] objectForKey:@"width"] intValue]],
                          @"screen_height": [NSString stringWithFormat:@"%d", [[[internal_source objectForKey:@"screen"] objectForKey:@"height"] intValue]],
                          @"connection_type": [self connectionType: [internal_source objectForKey:@"network"]],
                          @"device_id": [[internal_source objectForKey:@"device"] objectForKey:@"id"],
                          @"userAgentName": [[internal_source objectForKey:@"os"] objectForKey:@"name"],
                          @"userAgentVersion": [[internal_source objectForKey:@"os"] objectForKey:@"version"],
                          @"deviceName": [[internal_source objectForKey:@"device"] objectForKey:@"name"],
                         @"deviceBrand": [[internal_source objectForKey:@"device"] objectForKey:@"manufacturer"]
                      }};
        _internal_source = [dic copy];
        _event = [event copy];
    }
    return self;
}

-(NSString*)connectionType:(NSDictionary*)network
{
    if ([[network objectForKey:@"wifi"] intValue] == 1)
    {
        return @"wifi";
    }
    return @"cellular";
}

@end

@implementation PDContinueUserActivityPayload
@end


@implementation PDOpenURLPayload
@end
