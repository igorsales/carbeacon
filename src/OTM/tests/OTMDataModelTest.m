//
//  OTMDataModelTest.m
//  BTConnTest
//
//  Created by Igor Sales on 2015-10-04.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OTMDataModel.h"
#import "OTMPeerSharingLedger.h"

@interface OTMDataModelTest : XCTestCase

@property (nonatomic, strong) OTMDataModel* model;

@end

@implementation OTMDataModelTest

- (void)setUp
{
    [super setUp];
    
    self.model = [OTMDataModel new];
}

- (void)tearDown
{
    self.model = nil;

    [super tearDown];
}

- (void)testModel
{
    XCTAssertNotNil(self.model.ledger);
    XCTAssertTrue([self.model.ledger usersAllowedToReceive:@"carLocation"].count == 0);

    [self.model serialize];
    [self.model.ledger allowUserId:@"user1" asReceiverOf:@"carLocation" withOptions:nil];
    
    XCTAssertTrue([self.model.ledger usersAllowedToReceive:@"carLocation"].count == 1);
    
    self.model = [OTMDataModel deserializedModel];
    XCTAssertNotNil(self.model);

    XCTAssertTrue([self.model.ledger usersAllowedToReceive:@"carLocation"].count == 0);

    [self.model.ledger allowUserId:@"user1" asReceiverOf:@"carLocation" withOptions:nil];
    [self.model serialize];
    
    self.model = [OTMDataModel new];
    XCTAssertTrue([self.model.ledger usersAllowedToReceive:@"carLocation"].count == 0);
    
    self.model = [OTMDataModel deserializedModel];
    XCTAssertTrue([self.model.ledger usersAllowedToReceive:@"carLocation"].count == 1);
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"kOTMDataModel"];
    [defaults synchronize];

    self.model = [OTMDataModel deserializedModel];
    XCTAssertNotNil(self.model);
    XCTAssertTrue([self.model.ledger usersAllowedToReceive:@"carLocation"].count == 0);
}

@end
