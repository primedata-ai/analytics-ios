//
//  PropSerializationTests.m
//  AnalyticsTests
//
//  Created by Brandon Sneed on 11/20/19.
//  Copyright © 2019 PrimeData. All rights reserved.
//

#import <XCTest/XCTest.h>
@import PrimeData;

#pragma mark - Internal copy-overs for testing

JSON_DICT PDCoerceDictionary(NSDictionary *_Nullable dict);

@interface NSJSONSerialization (Serializable)
+ (BOOL)isOfSerializableType:(id)obj;
@end

@protocol PDSerializableDeepCopy <NSObject>
-(id _Nullable) serializableDeepCopy;
@end

@interface NSDictionary(SerializableDeepCopy) <PDSerializableDeepCopy>
@end

@interface NSArray(SerializableDeepCopy) <PDSerializableDeepCopy>
@end

@interface MyObject: NSObject <PDSerializable>
@end

@implementation MyObject
- (id)serializeToAppropriateType
{
    return @"MyObject";
}
@end

#pragma mark - Serialization Tests

@interface SerializationTests : XCTestCase

@end

@implementation SerializationTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testDeepCopyAndConformance {
    NSDictionary *nonserializable = @{@"test": @1, @"nonserializable": self, @"nested": @{@"nonserializable": self}, @"array": @[@1, @2, @3, self]};
    NSDictionary *serializable = @{@"test": @1, @"nonserializable": @0, @"nested": @{@"nonserializable": @0}, @"array": @[@1, @2, @3, @0]};

    NSDictionary *aCopy = [serializable serializableDeepCopy];
    XCTAssert(aCopy != serializable);
    
    NSDictionary *sub = [serializable objectForKey:@"nested"];
    NSDictionary *subCopy = [aCopy objectForKey:@"nested"];
    XCTAssert(sub != subCopy);

    NSDictionary *array = [serializable objectForKey:@"array"];
    NSDictionary *arrayCopy = [aCopy objectForKey:@"array"];
    XCTAssert(array != arrayCopy);

    XCTAssertNoThrow([serializable serializableDeepCopy]);
    XCTAssertThrows([nonserializable serializableDeepCopy]);
}

- (void)testPDSerialization {
    MyObject *myObj = [[MyObject alloc] init];
    NSDate *date = [NSDate date];
    NSData *data = [NSData data];
    NSURL *url = [NSURL URLWithString:@"http://segment.com"];
    NSString *test = @"test";

    XCTAssertFalse([NSJSONSerialization isOfSerializableType:data]);
    XCTAssertTrue([NSJSONSerialization isOfSerializableType:date]);
    XCTAssertTrue([NSJSONSerialization isOfSerializableType:url]);
    XCTAssertTrue([NSJSONSerialization isOfSerializableType:test]);

    NSDictionary *datevalue = @{@"test": date};
    NSDictionary *urlvalue = @{@"test": url};
    NSDictionary *numbervalue = @{@"test": @1};
    NSDictionary *myobjectvalue = @{@"test": myObj};

    XCTAssertNoThrow([datevalue serializableDeepCopy]);
    XCTAssertNoThrow([urlvalue serializableDeepCopy]);
    XCTAssertNoThrow([numbervalue serializableDeepCopy]);
    XCTAssertNoThrow([myobjectvalue serializableDeepCopy]);

    NSDictionary *nonserializable = @{@"test": @[data]};
    XCTAssertThrows([nonserializable serializableDeepCopy]);
    
    NSDictionary *testCoersion1 = @{@"test1": @[date], @"test2": url, @"test3": @1};
    NSDictionary *coersionResult1 = PDCoerceDictionary(testCoersion1);
    XCTAssertNotNil(coersionResult1);
    
    NSDictionary *testCoersion2 = @{@"test1": @[date], @"test2": url, @"test3": @1, @"test4": data};
    XCTAssertThrows(PDCoerceDictionary(testCoersion2));
}

@end