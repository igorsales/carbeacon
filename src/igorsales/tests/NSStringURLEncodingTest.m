//
//  NSStringURLEncodingTest.m
//  BTConnTest
//
//  Created by Igor Sales on 2015-10-01.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSString+URLEncoding.h"

@interface NSStringURLEncodingTest : XCTestCase

@end

@implementation NSStringURLEncodingTest

- (void)testStringEncodingAndDecoding
{
    XCTAssertEqualObjects(@"This%20is%20a%20test", [@"This is a test" URLEncodedString]);
    XCTAssertEqualObjects(@"a=b+c/d%E", [@"a%3Db%2Bc%2Fd%25E" URLDecodedString]);
    XCTAssertEqualObjects(@"a%3Db%2Bc%2Fd%25e", [@"a=b+c/d%e" URLEncodedString]);
    XCTAssertEqualObjects(@"a%3Db%2Bc%2Fd%25E", [@"a=b+c/d%E" URLEncodedString]);
}

@end
