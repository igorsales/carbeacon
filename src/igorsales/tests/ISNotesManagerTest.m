//
//  ISNotesManagerTest.m
//  BTConnTest
//
//  Created by Igor Sales on 2015-10-06.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ISNotesManager.h"
#import "ISKeychain.h"

@interface ISNotesManagerTest : XCTestCase

@property (nonatomic, strong) ISNotesManager* notesManager;

@end

@implementation ISNotesManagerTest

- (void)setUp
{
    [super setUp];
    
    self.notesManager = [[ISNotesManager alloc] initWithIdentifierSuffix:@"notesTest"];
}

- (void)tearDown
{
    self.notesManager = nil;

    [super tearDown];
}

- (void)testPublicKeyForPeerUserID
{
    NSData* keyData1 = [self.notesManager publicKeyDataForPeerUserId:@"user1" outbound:YES];
    XCTAssertNotNil(keyData1);

    NSData* keyData2 = [self.notesManager publicKeyDataForPeerUserId:@"user1" outbound:YES];
    XCTAssertNotNil(keyData2);

    XCTAssertEqualObjects(keyData1, keyData2);

    NSData* keyData3 = [self.notesManager publicKeyDataForPeerUserId:@"user2" outbound:YES];
    XCTAssertNotNil(keyData3);
    
    // Swap keys and check if they stick
    [self.notesManager installPublickKeyData:keyData3 forPeerUserId:@"user1"];
    [self.notesManager installPublickKeyData:keyData1 forPeerUserId:@"user2"];
    
    XCTAssertEqualObjects(keyData1, [self.notesManager publicKeyDataForPeerUserId:@"user2" outbound:NO]);
    XCTAssertEqualObjects(keyData3, [self.notesManager publicKeyDataForPeerUserId:@"user1" outbound:NO]);
    
    // test re-generation of keys
    [self.notesManager generateKeyPairForPeerUserId:@"user1"];
    NSData* keyData1_1 = [self.notesManager publicKeyDataForPeerUserId:@"user1" outbound:YES];
    XCTAssertNotEqualObjects(keyData1, keyData1_1);
}

- (void)testPublicAndPrivateKeyForPeerUserID
{
    ISNotesManager* notesManager2 = [[ISNotesManager alloc] initWithIdentifierSuffix:@"notesTest2"];

    // generate pair for users 1 and 2
    [self.notesManager generateKeyPairForPeerUserId:@"user1"];
    [notesManager2 generateKeyPairForPeerUserId:@"user2"];
    
    NSData* publicKey1 = [self.notesManager publicKeyDataForPeerUserId:@"user1" outbound:YES];
    NSData* publicKey2 = [notesManager2     publicKeyDataForPeerUserId:@"user2" outbound:YES];
    
    // install each other's public key
    [self.notesManager installPublickKeyData:publicKey2 forPeerUserId:@"user1"];
    [notesManager2     installPublickKeyData:publicKey1 forPeerUserId:@"user2"];
    
    // ensure public keys remained the same
    XCTAssertEqualObjects(publicKey1, [self.notesManager publicKeyDataForPeerUserId:@"user1" outbound:YES]);
    XCTAssertEqualObjects(publicKey2, [self.notesManager publicKeyDataForPeerUserId:@"user2" outbound:YES]);
    
    XCTAssertEqualObjects(publicKey1, [self.notesManager publicKeyDataForPeerUserId:@"user1" outbound:YES]);
    XCTAssertEqualObjects(publicKey2, [self.notesManager publicKeyDataForPeerUserId:@"user2" outbound:YES]);
}

- (void)testConcurrentNoteManagersSameIdentifier
{
    ISNotesManager* mgr1 = [[ISNotesManager alloc] initWithIdentifierSuffix:@"concurrent"];
    ISNotesManager* mgr2 = [[ISNotesManager alloc] initWithIdentifierSuffix:@"concurrent"];

    // wait for managers to be ready
    while (!mgr1.ready || !mgr2.ready) {
        [NSThread sleepForTimeInterval:1.0];
    }

    XCTAssertEqualObjects(mgr1.userId, mgr2.userId);
}

@end
