#import "PDPrimeDataIntegrationFactory.h"
#import "PDPrimeDataIntegration.h"


@implementation PDPrimeDataIntegrationFactory

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
    return [[PDPrimeDataIntegration alloc] initWithAnalytics:analytics httpClient:self.client fileStorage:self.fileStorage userDefaultsStorage:self.userDefaultsStorage];
}

- (NSString *)key
{
    return @"PrimeData.io";
}

@end
