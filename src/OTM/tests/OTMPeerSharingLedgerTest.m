//
//  OTMPeerSharingLedgerTest.m
//  BTConnTest
//
//  Created by Igor Sales on 2015-10-03.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OTMPeerSharingLedger.h"

@interface OTMPeerSharingLedgerTest : XCTestCase

@property (nonatomic, strong) OTMPeerSharingLedger* ledger;

@end

@implementation OTMPeerSharingLedgerTest

- (void)setUp
{
    [super setUp];
    
    self.ledger = [OTMPeerSharingLedger new];
}

- (void)tearDown
{
    self.ledger = nil;

    [super tearDown];
}

- (void)testLedger
{
    NSString* const category1 = @"carLocation";

    XCTAssert([self.ledger usersAllowedToReceive:category1].count == 0);
    
    [self.ledger allowUserId:@"user1" asReceiverOf:category1 withOptions:nil];

    XCTAssert([self.ledger usersAllowedToReceive:category1].count == 1);
    
    [self.ledger allowUserId:@"user2" asReceiverOf:category1 withOptions:@{@"key1": @"value1"}];

    NSArray* allowed = [self.ledger usersAllowedToReceive:category1];
    XCTAssertTrue(allowed.count == 2);
    XCTAssertTrue([allowed containsObject:@"user1"]);
    XCTAssertTrue([allowed containsObject:@"user2"]);
    
    [self.ledger preventUser:@"user1" fromReceiving:category1];

    allowed = [self.ledger usersAllowedToReceive:category1];
    XCTAssert(allowed.count == 1);
    XCTAssertFalse([allowed containsObject:@"user1"]);
    XCTAssertTrue([allowed containsObject:@"user2"]);
    XCTAssertEqualObjects(@{@"key1":@"value1"}, [self.ledger optionsToReceive:category1 forUser:@"user2"]);

    [self.ledger allowUserId:@"user3" asReceiverOf:@"userLocation" withOptions:@{@"key2": @"value2"}];

    allowed = [self.ledger usersAllowedToReceive:category1];
    XCTAssert(allowed.count == 1);
    XCTAssertFalse([allowed containsObject:@"user1"]);
    XCTAssertTrue([allowed containsObject:@"user2"]);
    XCTAssertFalse([allowed containsObject:@"user3"]);
    XCTAssertEqualObjects(@{@"key1":@"value1"}, [self.ledger optionsToReceive:category1 forUser:@"user2"]);

    allowed = [self.ledger usersAllowedToReceive:@"userLocation"];
    XCTAssert(allowed.count == 1);
    XCTAssertFalse([allowed containsObject:@"user1"]);
    XCTAssertFalse([allowed containsObject:@"user2"]);
    XCTAssertTrue([allowed containsObject:@"user3"]);
    XCTAssertEqualObjects(@{@"key2":@"value2"}, [self.ledger optionsToReceive:@"userLocation" forUser:@"user3"]);
    
    NSData* ledgerData = [NSKeyedArchiver archivedDataWithRootObject:self.ledger];
    
    self.ledger = nil;
    XCTAssertNil(self.ledger);
    
    self.ledger = [NSKeyedUnarchiver unarchiveObjectWithData:ledgerData];

    allowed = [self.ledger usersAllowedToReceive:category1];
    XCTAssert(allowed.count == 1);
    XCTAssertFalse([allowed containsObject:@"user1"]);
    XCTAssertTrue([allowed containsObject:@"user2"]);
    XCTAssertFalse([allowed containsObject:@"user3"]);
    XCTAssertEqualObjects(@{@"key1":@"value1"}, [self.ledger optionsToReceive:category1 forUser:@"user2"]);
    
    allowed = [self.ledger usersAllowedToReceive:@"userLocation"];
    XCTAssert(allowed.count == 1);
    XCTAssertFalse([allowed containsObject:@"user1"]);
    XCTAssertFalse([allowed containsObject:@"user2"]);
    XCTAssertTrue([allowed containsObject:@"user3"]);
    XCTAssertEqualObjects(@{@"key2":@"value2"}, [self.ledger optionsToReceive:@"userLocation" forUser:@"user3"]);
    
    [self.ledger preventUser:@"user3" fromReceiving:category1];
    allowed = [self.ledger usersAllowedToReceive:category1];
    XCTAssert(allowed.count == 1);
    XCTAssertFalse([allowed containsObject:@"user1"]);
    XCTAssertTrue([allowed containsObject:@"user2"]);
    XCTAssertFalse([allowed containsObject:@"user3"]);
    XCTAssertEqualObjects(@{@"key1":@"value1"}, [self.ledger optionsToReceive:category1 forUser:@"user2"]);
    XCTAssertEqualObjects(@{@"key2":@"value2"}, [self.ledger optionsToReceive:@"userLocation" forUser:@"user3"]);

    allowed = [self.ledger usersAllowedToReceive:@"userLocation"];
    XCTAssert(allowed.count == 1);

    [self.ledger preventUser:@"user3" fromReceiving:@"userLocation"];
    allowed = [self.ledger usersAllowedToReceive:@"userLocation"];
    XCTAssert(allowed.count == 0);
    
    OTMPeerSharingLedger* otherLedger = [self.ledger copy];
    XCTAssertNotEqual([self.ledger optionsToReceive:category1 forUser:@"user2"],
                      [otherLedger optionsToReceive:category1 forUser:@"user2"]);
    XCTAssertNotEqual([self.ledger usersAllowedToReceive:category1],
                      [otherLedger usersAllowedToReceive:category1]);
    XCTAssertEqualObjects([self.ledger optionsToReceive:category1 forUser:@"user2"],
                          [otherLedger optionsToReceive:category1 forUser:@"user2"]);
    XCTAssertEqualObjects([self.ledger usersAllowedToReceive:category1],
                          [otherLedger usersAllowedToReceive:category1]);
}

@end
