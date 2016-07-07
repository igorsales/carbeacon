//
//  OTMLocationObservationTest.m
//  BTConnTest
//
//  Created by Igor Sales on 2015-10-06.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "OTMLocationObservation.h"

@interface OTMLocationObservationTest : XCTestCase

@end

@implementation OTMLocationObservationTest

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testLocationObservationSerialization
{
    OTMLocationObservation* obs = [OTMLocationObservation new];
    
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:obs];
    
    OTMLocationObservation* obs2 = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    XCTAssertEqualObjects(obs, obs2);

    obs.location = [[CLLocation alloc] initWithLatitude:45 longitude:-74];
    obs2.location = [[CLLocation alloc] initWithLatitude:-45 longitude:74];
    
    XCTAssertNotEqualObjects(obs, obs2);
    
    obs.location = [[CLLocation alloc] initWithLatitude:45 longitude:-74];
    obs2.location = [[CLLocation alloc] initWithLatitude:45 longitude:-74];
    
    XCTAssertNotEqualObjects(obs, obs2);
    
    obs2.location = obs.location;
    
    XCTAssertEqualObjects(obs, obs2);
    
    obs.numberOfSendTries = obs2.numberOfSendTries = 3;

    XCTAssertEqualObjects(obs, obs2);

    obs = [OTMLocationObservation new];
    data = [NSKeyedArchiver archivedDataWithRootObject:obs];
    obs2 = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    XCTAssertEqualObjects(obs, obs2);
}

@end
