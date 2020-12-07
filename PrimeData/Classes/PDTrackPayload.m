#import "PDTrackPayload.h"


@implementation PDTrackPayload


- (instancetype)initWithEvent:(NSString*)event properties:(JSON_DICT)properties source:(JSON_DICT)source target:(JSON_DICT)target context:(JSON_DICT)context integrations:(JSON_DICT)integrations
{
    if (self =  [super initWithProperties:properties source:source target:target context:context integrations:integrations]) {
        _event = [event copy];
        _properties = [properties copy];
    }
    return self;
}

@end
