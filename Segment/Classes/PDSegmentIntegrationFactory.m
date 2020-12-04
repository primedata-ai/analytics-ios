#import "PDSegmentIntegrationFactory.h"
#import "PDSegmentIntegration.h"


@implementation PDSegmentIntegrationFactory

- (id)initWithHTTPClient:(PDHTTPClient *)client fileStorage:(id<PDStorage>)fileStorage userDefaultsStorage:(id<PDStorage>)userDefaultsStorage
{
    if (self = [super init]) {
        _client = client;
        _userDefaultsStorage = userDefaultsStorage;
        _fileStorage = fileStorage;
    }
    return self;
}

- (id<PDIntegration>)createWithSettings:(NSDictionary *)settings forAnalytics:(PDAnalytics *)analytics
{
    return [[PDSegmentIntegration alloc] initWithAnalytics:analytics httpClient:self.client fileStorage:self.fileStorage userDefaultsStorage:self.userDefaultsStorage];
}

- (NSString *)key
{
    return @"Segment.io";
}

@end
