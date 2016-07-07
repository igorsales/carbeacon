//
//  ISNotesManager.m
//  BTConnTest
//
//  Created by Igor Sales on 2015-09-25.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import "ISNotesManager.h"
#import "ISKeychain.h"
#import "NSBundle+Identifier.h"
#import "ISPKey.h"
#import "NSURLRequest+NotesAPI.h"

#import <UIKit/UIKit.h>

#define IS_LOG_LEVEL IS_LOG_LEVEL_DEBUG
#import "ISLog.h"

#ifdef DEBUG
#define DEBUG_PRIMARY_KEY 0
#endif

NSString* const kISNotesManagerReadyNotification = @"kISNotesManagerReadyNotification";

#define FORCE_NEW_USER 1

@interface ISNotesManager()

@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, strong) NSString* ownKeyIdentifier;
@property (nonatomic, strong) NSString* ownUserIdIdentifier;

@property (nonatomic, strong) ISKeychain* keychain;
@property (nonatomic, strong) ISPKey* myKey;
@property (atomic, copy)      NSString* userId;

@property (atomic, strong)    NSArray* receivedMessages;
@property (atomic, assign)    BOOL     ready;

@end

@implementation ISNotesManager

#pragma mark - Setup/teardown

- (id)init
{
    return [self initWithIdentifierSuffix:@"self"];
}

- (id)initWithIdentifierSuffix:(NSString*)suffix
{
    return [self initWithIdentifierSuffix:suffix runSynchronously:NO];
}

- (id)initWithIdentifierSuffix:(NSString*)suffix runSynchronously:(BOOL)synchronous
{
    if ((self = [super init])) {
        _keychain = [ISKeychain new];
        _ownKeyIdentifier    = [NSBundle identifierWithSuffix:[NSString stringWithFormat:@"key.%@", suffix]];
        _ownUserIdIdentifier = [NSBundle identifierWithSuffix:[NSString stringWithFormat:@"userId.%@", suffix]];
        _runSynchronously    = synchronous;

        _callbackQueue       = dispatch_get_main_queue();
        
        NSString* queueName = [NSString stringWithFormat:@"ca.igorsales.queue.notesManager.%@", suffix];
        
        _queue = dispatch_queue_create([queueName cStringUsingEncoding:NSUTF8StringEncoding],
                                       DISPATCH_QUEUE_CONCURRENT);
        
        [self retrieveCredentials];
    }
    
    return self;
}

#pragma mark - Accessors

#pragma mark - Private

- (void)retrieveCredentials
{
    self.myKey  = [self.keychain keyPairForIdentifier:self.ownKeyIdentifier createIfNil:NO];
    self.userId = [self.keychain stringForKey:self.ownUserIdIdentifier];
 
    if (self.myKey && self.userId) {
        self.ready = YES;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kISNotesManagerReadyNotification
                                                            object:self
                                                          userInfo:nil];

        return;
    }
    
    // At this point, we know we don't have creds, or are incomplete, so reset them
    [self resetIdentity];
}

- (void)resetUserIdAndKey
{
    [self.keychain removePeerPublicKeyWithIdentifier:self.ownKeyIdentifier];
    [self.keychain setString:nil forKey:self.ownUserIdIdentifier];
    
    self.userId = nil;
    self.myKey = nil;
}

- (void)generateCredentials
{
    ISLogInfo(@"Generating credentials");

    self.myKey = [self.keychain keyPairForIdentifier:self.ownKeyIdentifier createIfNil:YES];
    
    NSString* userId = [self.keychain stringForKey:self.ownUserIdIdentifier];
    
    if (!userId) {
        NSInteger tryCount = 5;
        BOOL running = NO;
        userId = [NSUUID UUID].UUIDString;

        ISLogInfo(@"Trying to create user with userID: %@", userId);

        do {
            // 400 - public key is not correct or invalid
            // 403 - Unauthorized: userId is already taken
            // 500 - Server error: Couldn't create user
            
            NSUInteger statusCode = [self statusCodeForCreatedNewUserWithId:userId withNewPublicKeyPEM:
                                     [self.keychain PEMForPublicKey:self.myKey]];
            
            switch (statusCode) {
                case 201: // User created
                    [self.keychain setString:userId forKey:self.ownUserIdIdentifier];
                    break;
                    
                case 0: // No response from server
                    ISLogInfo(@"Waiting some time to try retrieving credentials again");
                    [NSThread sleepForTimeInterval:60.0];

                default:
                case 400:
                case 500:
                    if (tryCount == 1) { // last chance
                        // TODO: Notify user and HQ about this problem
                    }
                    break;
                    
                case 403:
                    // UserId already taken. Create new one
                    userId = [NSUUID UUID].UUIDString;
                    running = YES;
                    break;
            }
        } while(running && --tryCount > 0);
    }
    
    if (userId) {
        self.userId = userId;
        self.ready  = YES;
    
#if DEBUG_PRIMARY_KEY
        NSString* keyPEM = [self.keychain PEMForPublicKey:self.myKey];
        ISLogDebug(@"This user's userId: %@", self.userId);
        ISLogDebug(@"This user's public key:\n%@", keyPEM);
#endif
    } else {
        ISLogError(@"Could not generate user credentials!");
        // TODO: Handle the case where the user creation wasn't successful.
        // Essentially it needs to keep trying until succesful
    }
    
    dispatch_async(self.callbackQueue, ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kISNotesManagerReadyNotification
                                                            object:self
                                                          userInfo:nil];
    });
}

- (void)runRequest:(NSURLRequest*)request
 completionHandler:(void (^)(NSURLResponse* response,
                             NSData* data,
                             NSError* error))handler
{
    NSAssert(handler, @"handler cannot be nil");

    void(^block)() = ^(){
        NSHTTPURLResponse* resp = nil;
        NSError* error = nil;
        
        NSData* data = [NSURLConnection sendSynchronousRequest:request
                                             returningResponse:&resp
                                                         error:&error];

        dispatch_async(self.callbackQueue, ^{
            handler(resp, data, error);
        });
    };
    
    if (self.runSynchronously) {
        dispatch_sync(self.queue, block);
    } else {
        dispatch_async(self.queue, block);
    }
}

- (NSUInteger)statusCodeForCreatedNewUserWithId:(NSString*)userId
                            withNewPublicKeyPEM:(NSString*)publicKeyPEM
{
    // NOTE: This call is meant to be used synchronously, hence private
    NSURLRequest* req = [NSURLRequest requestNewUserWithId:userId
                                                     label:[UIDevice currentDevice].name
                                              publicKeyPEM:publicKeyPEM];

    __autoreleasing NSHTTPURLResponse* resp = nil;
    __autoreleasing NSError* error = nil;
    
    [NSURLConnection sendSynchronousRequest:req
                          returningResponse:&resp
                                      error:&error];
    
    return ((NSHTTPURLResponse*)resp).statusCode;
}

- (NSString*)keyIdForUserId:(NSString*)userId outbound:(BOOL)outbound
{
    return [NSBundle identifierWithSuffix:[NSString stringWithFormat:@"key%@.%@",
                                           outbound ? @"To" : @"From",
                                           [userId lowercaseString]]];
}

#pragma mark - Operations

- (void)resetIdentity
{
    if (self.runSynchronously) {
        dispatch_barrier_sync(self.queue, ^{
            [self resetUserIdAndKey];
            [self generateCredentials];
        });
    } else {
        dispatch_barrier_async(self.queue, ^{
            [self resetUserIdAndKey];
            [self generateCredentials];
        });
    }
}

- (void)pingServerWithCompletionBlock:(void(^)(NSTimeInterval elapsed, NSError* error))block
{
    NSURLRequest* req = [NSURLRequest requestToPingServer];
    
    NSDate* past = [NSDate date];
    
    [self runRequest:req completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (block) {
            block(-past.timeIntervalSinceNow, error);
        }
    }];
}

- (void)sendMessage:(NSString*)message
                 to:(NSString*)destUserId
    completionBlock:(void (^)(NSError *))block
{
    if (!block) {
        block = ^(NSError* error) {};
    }

    NSURLRequest* req = [NSURLRequest requestToSendMessage:message
                                                fromUserId:self.userId
                                                  toUserId:destUserId
                                             signedWithKey:self.myKey];

    [self runRequest:req completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSUInteger statusCode = ((NSHTTPURLResponse*)response).statusCode;
        if (statusCode != 201) {
            if (!error) {
                NSString* errorDescription = @"Unknown error";
                if (data.length) {
                    errorDescription = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                }
                
                error = [NSError errorWithDomain:NSURLErrorDomain
                                            code:statusCode
                                        userInfo:@{
                                                   @"statusCode": @(statusCode),
                                                   NSLocalizedDescriptionKey: errorDescription
                                                   }];
            }
        }

        block(error);
    }];
}

- (void)encryptAndSendMessageData:(NSData*)messageData
                               to:(NSString*)destUserId
                  completionBlock:(void(^)(NSError* error))block
{
    if (!block) {
        block = ^(NSError* error) {};
    }

    // outbound because we use the user's public key to encrypt (outbound keys include private and public)
    NSString* keyId = [self keyIdForUserId:destUserId outbound:NO];
    
    ISPKey* pkey = [self.keychain keyPairForIdentifier:keyId createIfNil:NO];
    
    if (!pkey) {
        block([NSError errorWithDomain:NSArgumentDomain
                                  code:NSFileNoSuchFileError
                              userInfo:@{NSLocalizedDescriptionKey: @"destination user key not found"}]);
        return;
    }
    
    NSData* encrypted = [pkey encryptedData:messageData];
    
    [self sendMessage:[encrypted base64EncodedStringWithOptions:0]
                   to:destUserId
      completionBlock:block];
}

- (void)fetchIncomingMessagesWithCompletionBlock:(void(^)(NSArray* newMessages, NSError* error))block;
{
    if (!block) {
        block = ^(NSArray* newMessages, NSError* error) {};
    }

    NSURLRequest* req = [NSURLRequest requestToRetrieveMessagesForUserId:self.userId
                                                           signedWithKey:self.myKey];
    
    [self runRequest:req completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSUInteger statusCode = ((NSHTTPURLResponse*)response).statusCode;
        if (statusCode == 200) {
            __autoreleasing NSError* jsonError = nil;
            NSArray* messages = [NSJSONSerialization JSONObjectWithData:data
                                                                options:0
                                                                  error:&jsonError];
            
            if (messages) {
                self.receivedMessages = messages;
            }
            
            block(messages, jsonError);
        } else {
            if (!error) {
                NSString* errorDescription = @"No description";
                if (data.length) {
                    errorDescription = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                }
                error = [NSError errorWithDomain:NSURLErrorDomain
                                            code:statusCode
                                        userInfo:@{
                                                   NSLocalizedDescriptionKey:errorDescription}];
            }
            block(nil, error);
        }
    }];
}

- (void)fetchAndDecryptIncomingMessagesWithCompletionBlock:(void (^)(NSArray *, NSError *))block
{
    if (!block) {
        block = ^(NSArray* newMessages, NSError* error) {};
    }

    [self fetchIncomingMessagesWithCompletionBlock:^(NSArray *newMessages, NSError *error) {
        if (!error) {
            NSMutableArray* messages = [newMessages mutableCopy];
            
            [newMessages enumerateObjectsUsingBlock:^(NSDictionary* dict, NSUInteger idx, BOOL* stop) {
                NSString* fromUserId = dict[@"from"];
                NSString* what       = dict[@"what"];
                
                if (fromUserId && what) {
                    // inbound because we use our own private key to decrypt
                    NSString* keyId     = [self keyIdForUserId:fromUserId outbound:YES];
                    NSData*   encrypted = [[NSData alloc] initWithBase64EncodedString:what
                                                                              options:0];
                    if (encrypted) {
                        ISPKey* pkey = [self.keychain keyPairForIdentifier:keyId createIfNil:NO];
                        
                        if (pkey) {
                            NSData* decrypted = [pkey decryptedData:encrypted];
                            if (decrypted) {
                                NSMutableDictionary* newDict = [dict mutableCopy];
                                newDict[@"what"] = [[NSString alloc] initWithData:decrypted
                                                                         encoding:NSUTF8StringEncoding];
                                [messages replaceObjectAtIndex:idx withObject:newDict];
                            } else {
                                ISLogDebug(@"Could not decrypt message from %@", fromUserId);
                            }
                        } else {
                            ISLogDebug(@"No private key to decode message from %@", fromUserId);
                        }
                    } else {
                        ISLogDebug(@"Could not understand message from %@ (%@)", fromUserId, what);
                    }
                }
            }];
            
            newMessages = messages;
        }
        
        block(newMessages, error);
    }];
}

- (void)updatePushNotificationsDeviceToken:(NSData*)token completionBlock:(void (^)(NSError *))block
{
    if (!block) {
        block = ^(NSError* error) {};
    }
    
    NSURLRequest* req = [NSURLRequest requestToPutDeviceToken:token.description
                                                    forUserId:self.userId
                                                    signedWithKey:self.myKey];
    
    [self runRequest:req completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSUInteger statusCode = ((NSHTTPURLResponse*)response).statusCode;
        if (statusCode == 200 || statusCode == 201) {
            block(nil);
        } else {
            if (!error) {
                NSString* errorDescription = @"No description";
                if (data.length) {
                    errorDescription = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                }
                error = [NSError errorWithDomain:NSURLErrorDomain
                                            code:statusCode
                                        userInfo:@{
                                                   NSLocalizedDescriptionKey:errorDescription}];
                ISLogError(@"URL failed :%@", req.URL);
            }
            block(error);
        }
    }];
}

- (void)generateKeyPairForPeerUserId:(NSString *)userId
{
    // When we generate a pair, we want the key to be used for sending to the other user
    NSString* keyId = [self keyIdForUserId:userId outbound:YES];
    [self.keychain generateKeyPairForIdentifier:keyId];
}

- (NSData*)publicKeyDataForPeerUserId:(NSString *)userId outbound:(BOOL)outbound
{
    NSString* keyId = [self keyIdForUserId:userId outbound:outbound];

    ISPKey* pkey = [self.keychain keyPairForIdentifier:keyId createIfNil:outbound];
    
    return [self.keychain RSAKeyDataForIdentifier:pkey.identifier public:YES];
}

- (void)installPublickKeyData:(NSData*)keyData forPeerUserId:(NSString *)userId
{
    NSString* keyId = [self keyIdForUserId:userId outbound:NO];
    
    ISLogInfo(@"Installing public key for %@", userId);

    [self.keychain removePeerPublicKeyWithIdentifier:keyId];
    [self.keychain addPeerPublicKeyWithIdentifier:keyId keyBits:keyData];
}

- (NSData*)signString:(NSString*)string withPeerUserId:(NSString*)userId
{
    // We sign using our own private key, and it can be verified with the public key
    NSString* keyId = [self keyIdForUserId:userId outbound:YES];
    
    ISPKey* pkey = [self.keychain keyPairForIdentifier:keyId createIfNil:NO];
    
    if (!pkey) {
        return nil;
    }
    
    return [pkey signatureForData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

- (BOOL)verifyString:(NSString *)string signature:(NSData*)signature fromPeerUserId:(NSString *)userId
{
    // We verify a string with the user's public key
    NSString* keyId = [self keyIdForUserId:userId outbound:NO];
    
    ISPKey* pkey = [self.keychain keyPairForIdentifier:keyId createIfNil:NO];
    
    if (!pkey) {
        return NO;
    }

    return [pkey verifySignature:signature onData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

@end
