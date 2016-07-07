//
//  ISNotesManager.h
//  BTConnTest
//
//  Created by Igor Sales on 2015-09-25.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const kISNotesManagerReadyNotification;

@class ISKeychain;

@interface ISNotesManager : NSObject

@property (atomic, copy, readonly)    NSString* userId;
@property (atomic, readonly)          BOOL      runSynchronously;

@property (atomic, readonly)          NSArray*  receivedMessages;
@property (atomic, readonly)          BOOL      ready;

// Unless otherwise specified, the callback queue is always the main queue
@property (nonatomic, strong)         dispatch_queue_t callbackQueue;


// NOTE: You are responsible for ensuring only one notes manager per suffix is created in your app
- (id)init;
- (id)initWithIdentifierSuffix:(NSString*)suffix;
- (id)initWithIdentifierSuffix:(NSString*)suffix runSynchronously:(BOOL)synchronous;

- (void)resetIdentity;

- (void)pingServerWithCompletionBlock:(void(^)(NSTimeInterval elapsed, NSError* error))block;

- (void)sendMessage:(NSString*)message
                 to:(NSString*)destUserId
    completionBlock:(void(^)(NSError* error))block;

- (void)encryptAndSendMessageData:(NSData*)messageData
                               to:(NSString*)destUserId
                  completionBlock:(void(^)(NSError* error))block;

- (void)fetchIncomingMessagesWithCompletionBlock:(void(^)(NSArray* newMessages, NSError* error))block;

- (void)fetchAndDecryptIncomingMessagesWithCompletionBlock:(void(^)(NSArray* newMessages, NSError* error))block;

- (void)updatePushNotificationsDeviceToken:(NSData*)token completionBlock:(void(^)(NSError* error))block;

- (void)generateKeyPairForPeerUserId:(NSString*)userId;
- (NSData*)publicKeyDataForPeerUserId:(NSString*)userId outbound:(BOOL)outbound;
- (void)installPublickKeyData:(NSData*)keyData forPeerUserId:(NSString *)userId;

- (NSData*)signString:(NSString*)string withPeerUserId:(NSString*)userId;
- (BOOL)verifyString:(NSString *)string signature:(NSData*)signature fromPeerUserId:(NSString *)userId;

@end
