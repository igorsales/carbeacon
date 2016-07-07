//
//  CarBeaconIntegrationTest.m
//  BTConnTest
//
//  Created by Igor Sales on 2015-09-30.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ISKeychain.h"
#import "ISPKey.h"
#import "ISNotesManager.h"
#import "NSString+URLEncoding.h"
#import "NSBundle+Identifier.h"

//#define NOTES_SERVER_URL @"http://localhost:56789"

NSString* const kIdentifier1 = @"ca.igorsales.CarBeacon.testIntegrationUser1";
NSString* const kIdentifier2 = @"ca.igorsales.CarBeacon.testIntegrationUser2";

@interface CarBeaconIntegrationTest : XCTestCase

@property (nonatomic, strong) ISKeychain* keychain;

@end

@implementation CarBeaconIntegrationTest

- (void)setUp
{
    [super setUp];
    
    self.keychain = [ISKeychain new];
}

- (void)tearDown
{
    [super tearDown];
}

#define DECL_QUERY \
    NSData* data = nil; \
    NSMutableURLRequest* req = nil; \
    __autoreleasing NSHTTPURLResponse* resp = nil; \
    __autoreleasing NSError* error = nil

#define GET(U) \
    req = [NSMutableURLRequest requestWithURL:U]; \
    resp = nil; \
    error = nil; \
    data = [NSURLConnection sendSynchronousRequest:req \
                                     returningResponse:&resp \
                                                 error:&error]

#define POST \
    resp = nil; \
    error = nil; \
    [req setHTTPMethod:@"POST"]; \
    data = [NSURLConnection sendSynchronousRequest:req \
                                 returningResponse:&resp \
                                             error:&error]

- (void)testPing
{
    NSURL* URL = [NSURL URLWithString:NOTES_SERVER_URL @"/ping"];
    
    DECL_QUERY;
    
    GET(URL);
    
    XCTAssertNotNil(data);
    XCTAssert(data.length > 0);
}

- (void)testNewUsersAndMessage
{
    NSURL* URL = [NSURL URLWithString:NOTES_SERVER_URL @"/user/new"];
    
    DECL_QUERY;
    
    // Create User 1
    [self.keychain removePeerPublicKeyWithIdentifier:kIdentifier1];
    ISPKey* pkey1 = [self.keychain keyPairForIdentifier:kIdentifier1 createIfNil:YES];
    
    NSString* user1Id    = [[NSUUID UUID] UUIDString];
    NSString* publicKey1 = [self.keychain PEMForPublicKey:pkey1];

    NSDictionary* payload = @{
                              @"name": user1Id,
                              @"public_key": publicKey1 };

    req = [[NSMutableURLRequest alloc] initWithURL:URL];
    
    error = nil;
    [req setHTTPBody:[NSJSONSerialization dataWithJSONObject:payload
                                                     options:0
                                                       error:&error]];
    XCTAssertNil(error);
    
    POST;
    
    XCTAssertNil(error);
    XCTAssertEqual(201, resp.statusCode);
    
    // Create User 2
    [self.keychain removePeerPublicKeyWithIdentifier:kIdentifier2];
    ISPKey* pkey2 = [self.keychain keyPairForIdentifier:kIdentifier2 createIfNil:YES];
    
    NSString* user2Id    = [[NSUUID UUID] UUIDString];
    NSString* publicKey2 = [self.keychain PEMForPublicKey:pkey2];
    
    payload = @{
                @"name": user2Id,
                @"public_key": publicKey2
                };
    
    req = [[NSMutableURLRequest alloc] initWithURL:URL];
    
    error = nil;
    [req setHTTPBody:[NSJSONSerialization dataWithJSONObject:payload
                                                     options:0
                                                       error:&error]];
    XCTAssertNil(error);
    
    POST;
    
    XCTAssertNil(error);
    XCTAssertEqual(201, resp.statusCode);
    
    // User 1 sends User 2 a message
    NSString* message = @"Hey you!";
    NSData*   messageData = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSData*   signature = [pkey1 signatureForData:messageData];
    URL = [NSURL URLWithString:[NSString stringWithFormat:NOTES_SERVER_URL @"/message/from/%@/to/%@", user1Id, user2Id]];
    
    payload = @{
                @"what": message,
                @"signed": [signature base64EncodedStringWithOptions:0]
                };
    
    req = [[NSMutableURLRequest alloc] initWithURL:URL];
    
    error = nil;
    [req setHTTPBody:[NSJSONSerialization dataWithJSONObject:payload
                                                     options:0
                                                       error:&error]];
    XCTAssertNil(error);
    
    POST;
    
    // User 2 retrieves the message
    long ts = (long)[NSDate date].timeIntervalSince1970;
    NSString* salt = @"abcd";
    
    NSString* toSign = [NSString stringWithFormat:@"%@-%ld-%@", user2Id, ts, salt];
    NSData* toSignData = [toSign dataUsingEncoding:NSUTF8StringEncoding];
    signature = [pkey2 signatureForData:toSignData];
    NSString* signatureString = [signature base64EncodedStringWithOptions:0];
    
    NSString* path = [NSString stringWithFormat:@"/messages/to/%@/dated/%ld/salt/%@/signed/%@", user2Id, ts, salt, signatureString];

    URL = [NSURL URLWithString:[NSString stringWithFormat:NOTES_SERVER_URL @"%@/%@", path, signatureString]];
    
    GET(URL);
    
    XCTAssertNil(error);
    XCTAssertEqual(resp.statusCode, 200);
    
    NSArray* messages = [NSJSONSerialization JSONObjectWithData:data
                                                        options:0
                                                          error:&error];
    XCTAssertNil(error);
    XCTAssertGreaterThan(messages.count, 0);
    
    XCTAssertEqualObjects(user1Id, messages[0][@"from"]);
    XCTAssertEqualObjects(message, messages[0][@"what"]);
    XCTAssertNotNil(messages[0][@"when"]);
}

- (void)testNewUsersAndMessageUsingNotesManager
{
    // First erase traces in the keychain
    [self.keychain setString:nil forKey:[NSBundle identifierWithSuffix:@"userId.user1"]];
    [self.keychain setString:nil forKey:[NSBundle identifierWithSuffix:@"userId.user2"]];
    [self.keychain removePeerPublicKeyWithIdentifier:[NSBundle identifierWithSuffix:@"key.user1"]];
    [self.keychain removePeerPublicKeyWithIdentifier:[NSBundle identifierWithSuffix:@"key.user2"]];

    ISNotesManager* mgr1 = [[ISNotesManager alloc] initWithIdentifierSuffix:@"user1" runSynchronously:YES];
    ISNotesManager* mgr2 = [[ISNotesManager alloc] initWithIdentifierSuffix:@"user2" runSynchronously:YES];

    XCTAssertTrue(mgr1.ready);
    XCTAssertTrue(mgr2.ready);
    
    XCTAssertNotNil(mgr1.userId);
    XCTAssertNotNil(mgr2.userId);
    
    [mgr1 sendMessage:@"Message to 2" to:mgr2.userId completionBlock:^(NSError *error) {
        XCTAssertNil(error);
    }];
    
    [mgr2 sendMessage:@"Message to 1" to:mgr1.userId completionBlock:nil];
    
    [mgr1 fetchIncomingMessagesWithCompletionBlock:^(NSArray *newMessages, NSError *error) {
        XCTAssertNil(error);
        XCTAssertGreaterThan(newMessages.count, 0);
        XCTAssertEqualObjects(@"Message to 1", newMessages[0][@"what"]);
        XCTAssertEqualObjects(mgr2.userId, newMessages[0][@"from"]);
    }];

    [mgr2 fetchIncomingMessagesWithCompletionBlock:^(NSArray *newMessages, NSError *error) {
        XCTAssertNil(error);
        XCTAssertGreaterThan(newMessages.count, 0);
        XCTAssertEqualObjects(@"Message to 2", newMessages[0][@"what"]);
        XCTAssertEqualObjects(mgr1.userId, newMessages[0][@"from"]);
    }];
}

- (void)testAsyncPing
{
    ISNotesManager* mgr = [[ISNotesManager alloc] initWithIdentifierSuffix:@"ping"];
    
    [mgr pingServerWithCompletionBlock:^(NSTimeInterval elapsed, NSError *error) {
        XCTAssertNil(error);
        XCTAssertGreaterThan(elapsed, 0);
        NSLog(@"Server ping time: %.5f", elapsed);
    }];
}

- (void)testNewUsersAndEncryptedMessageUsingNotesManager
{
    // First erase traces in the keychain
    [self.keychain setString:nil forKey:[NSBundle identifierWithSuffix:@"userId.user1"]];
    [self.keychain setString:nil forKey:[NSBundle identifierWithSuffix:@"userId.user2"]];
    [self.keychain removePeerPublicKeyWithIdentifier:[NSBundle identifierWithSuffix:@"key.user1"]];
    [self.keychain removePeerPublicKeyWithIdentifier:[NSBundle identifierWithSuffix:@"key.user2"]];
    
    ISNotesManager* mgr1 = [[ISNotesManager alloc] initWithIdentifierSuffix:@"user1" runSynchronously:YES];
    ISNotesManager* mgr2 = [[ISNotesManager alloc] initWithIdentifierSuffix:@"user2" runSynchronously:YES];
    
    XCTAssertTrue(mgr1.ready);
    XCTAssertTrue(mgr2.ready);
    
    XCTAssertNotNil(mgr1.userId);
    XCTAssertNotNil(mgr2.userId);
    
    [mgr1 encryptAndSendMessageData:[@"Message to 2" dataUsingEncoding:NSUTF8StringEncoding]
                                 to:mgr2.userId
                    completionBlock:^(NSError *error) {
        XCTAssertNil(error);
    }];
    
    [mgr2 encryptAndSendMessageData:[@"Message to 1" dataUsingEncoding:NSUTF8StringEncoding]
                             to:mgr1.userId
                completionBlock:nil];
    
    [mgr1 fetchAndDecryptIncomingMessagesWithCompletionBlock:^(NSArray *newMessages, NSError *error) {
        XCTAssertNil(error);
        XCTAssertGreaterThan(newMessages.count, 0);
        XCTAssertEqualObjects(@"Message to 1", newMessages[0][@"what"]);
        XCTAssertEqualObjects(mgr2.userId, newMessages[0][@"from"]);
    }];
    
    [mgr2 fetchAndDecryptIncomingMessagesWithCompletionBlock:^(NSArray *newMessages, NSError *error) {
        XCTAssertNil(error);
        XCTAssertGreaterThan(newMessages.count, 0);
        XCTAssertEqualObjects(@"Message to 2", newMessages[0][@"what"]);
        XCTAssertEqualObjects(mgr1.userId, newMessages[0][@"from"]);
    }];
}


@end
