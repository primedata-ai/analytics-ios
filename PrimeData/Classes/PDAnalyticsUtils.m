#import "PDAnalyticsUtils.h"
#import "PDAnalytics.h"
#import "PDUtils.h"

static BOOL kAnalyticsLoggerShowLogs = NO;

#pragma mark - Logging

void PDSetShowDebugLogs(BOOL showDebugLogs)
{
    kAnalyticsLoggerShowLogs = showDebugLogs;
}

void PDLog(NSString *format, ...)
{
    if (!kAnalyticsLoggerShowLogs)
        return;

    va_list args;
    va_start(args, format);
    NSLogv(format, args);
    va_end(args);
}

#pragma mark - Serialization Extensions

@interface NSDate(PDSerializable)<PDSerializable>
- (id)serializeToAppropriateType;
@end

@implementation NSDate(PDSerializable)
- (id)serializeToAppropriateType
{
    return iso8601FormattedString(self);
}
@end

@interface NSURL(PDSerializable)<PDSerializable>
- (id)serializeToAppropriateType;
@end

@implementation NSURL(PDSerializable)
- (id)serializeToAppropriateType
{
    return [self absoluteString];
}
@end


