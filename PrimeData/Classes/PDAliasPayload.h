#import <Foundation/Foundation.h>
#import "PDPayload.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AliasPayload)
@interface PDAliasPayload : PDPayload

@property (nonatomic, readonly) NSString *theNewId;

- (instancetype)initWithNewId:(NSString *)newId
                      context:(JSON_DICT)context
                 integrations:(JSON_DICT)integrations;

@end

NS_ASSUME_NONNULL_END
