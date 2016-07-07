//
//  NSBundleIdentifierTest.m
//  BTConnTest
//
//  Created by Igor Sales on 2015-09-30.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSBundle+Identifier.h"

@interface NSBundleIdentifierTest : XCTestCase

@end

@implementation NSBundleIdentifierTest

- (void)testSuffix
{
    // Note: This test only works on a real target, not on logic tests
    XCTAssertEqualObjects(@"ca.igorsales.BTConnTest.suffix", [[NSBundle mainBundle] identifierWithSuffix:@"suffix"]);
    XCTAssertEqualObjects(@"ca.igorsales.BTConnTest.suffix2", [NSBundle identifierWithSuffix:@"suffix2"]);
}

@end
