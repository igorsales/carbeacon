//
//  NSURLRequest+NotesAPI.m
//  BTConnTest
//
//  Created by Igor Sales on 2015-10-01.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import "NSURLRequest+NotesAPI.h"
#import "ISPKey.h"

#import "ISLog.h"

#ifndef NOTES_SERVER_URL

#if defined(IS_UNDER_TEST)
#define NOTES_SERVER_URL @"http://localhost:56789"
//#define NOTES_SERVER_URL @"https://localhost:56790"
#else
#define NOTES_SERVER_URL @"https://notes.igorsales.ca"
#endif

#endif

#define kTimeout (30.0)


#define kISNotesAPIPing        @"/ping"
#define kISNotesAPINewUser     @"/user/new"
#define kISNotesSendMessage    @"/message/from/%@/to/%@"
#define kISNotesGetMessages    @"/messages/to/%@/dated/%ld/salt/%@/signed/%@"
#define kISNotesPutDeviceToken @"/device/token/for/%@/dated/%ld/salt/%@/signed/%@"

#define kISNotesSignature   @"%@-%ld-%@"


static NSURL* sURL = nil;

@implementation NSURLRequest (NotesAPI)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self notesAPIServerURL];
    });
}

#pragma mark - Class accessors

+ (NSURL*)notesAPIServerURL
{
    if (!sURL) {
        sURL = [NSURL URLWithString:NOTES_SERVER_URL];
    }

    return sURL;
}

+ (void)setNotesAPIServerURL:(NSURL*)URL
{
    sURL = URL;
}

#pragma mark - Initializers

+ (NSURLRequest*)requestToPingServer
{
    NSURL* URL = [[self notesAPIServerURL] URLByAppendingPathComponent:@"/ping"];
    return [NSURLRequest requestWithURL:URL
                            cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                        timeoutInterval:kTimeout];
}

+ (NSURLRequest*)requestNewUserWithId:(NSString*)userId
                                label:(NSString *)label
                         publicKeyPEM:(NSString*)publicKeyPEM
{
    NSAssert(userId, @"User ID cannot be nil!");

    NSURL* URL = [[self notesAPIServerURL] URLByAppendingPathComponent:kISNotesAPINewUser];
    
    NSMutableDictionary* payload = [NSMutableDictionary dictionaryWithDictionary:@{
                              @"name":       userId,
                              @"public_key": publicKeyPEM
                              }];
    
    if (label.length) {
        payload[@"label"] = label;
    }
    
    __autoreleasing NSError* error = nil;
    NSData* body = [NSJSONSerialization dataWithJSONObject:payload
                                                   options:0
                                                     error:&error];
    if (error) {
        return nil;
    }

    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:URL
                                                       cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                   timeoutInterval:kTimeout];
    [req setHTTPMethod:@"POST"];
    [req setHTTPBody:body];
    [req addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    return req;
}

+ (NSURLRequest*)requestToSendMessage:(NSString*)message
                           fromUserId:(NSString*)fromUserId
                             toUserId:(NSString*)toUserId
                        signedWithKey:(ISPKey*)key
{
    NSAssert(fromUserId, @"From user ID cannot be nil!");

    NSData*   messageData = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSData*   signature   = [key signatureForData:messageData];
    NSString* path        = [NSString stringWithFormat:kISNotesSendMessage,
                             fromUserId,
                             toUserId];
    NSURL*    URL         = [[self notesAPIServerURL] URLByAppendingPathComponent:path];
    
    NSDictionary* payload = @{
                              @"what": message,
                              @"signed": [signature base64EncodedStringWithOptions:0]
                              };
    
    
    __autoreleasing NSError* error = nil;
    NSData* body = [NSJSONSerialization dataWithJSONObject:payload
                                                   options:0
                                                     error:&error];
    if (error) {
        return nil;
    }

    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:URL
                                                       cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                   timeoutInterval:kTimeout];
    [req setHTTPMethod:@"POST"];
    [req setHTTPBody:body];
    
    return req;
}

+ (NSURLRequest*)requestToRetrieveMessagesForUserId:(NSString*)userId
                                          signedWithKey:(ISPKey*)key
{
    NSAssert(userId, @"User ID cannot be nil!");

    NSString* salt            = [[NSUUID UUID].UUIDString stringByReplacingOccurrencesOfString:@"-" withString:@""];
    if (salt.length > 8) {
        salt = [salt substringToIndex:8];
    }
    
    // Signature format = "#{userId}-#{epoch}-#{salt}"
    long      ts              = (long)[NSDate date].timeIntervalSince1970;
    NSString* toSign          = [NSString stringWithFormat:kISNotesSignature,
                                 userId,
                                 ts,
                                 salt];
    NSData*   toSignData      = [toSign dataUsingEncoding:NSUTF8StringEncoding];
    NSData*   signature       = [key signatureForData:toSignData];
    NSString* signatureString = [signature base64EncodedStringWithOptions:0];
    
    NSString* path            = [NSString stringWithFormat:kISNotesGetMessages,
                                 userId,
                                 ts,
                                 salt,
                                 signatureString];
    NSURL*    URL             = [[self notesAPIServerURL] URLByAppendingPathComponent:path];
    
    NSURLRequest* req = [NSURLRequest requestWithURL:URL
                                         cachePolicy:NSURLRequestReloadIgnoringCacheData
                                     timeoutInterval:kTimeout];
    
    return req;
}

+ (NSURLRequest*)requestToPutDeviceToken:(NSString *)token
                               forUserId:(NSString *)userId
                               signedWithKey:(ISPKey *)key
{
    NSAssert(userId, @"User ID cannot be nil!");
    NSAssert(token.length > 0, @"Token cannot be nil or empty");
    
    NSString* salt            = [[NSUUID UUID].UUIDString stringByReplacingOccurrencesOfString:@"-" withString:@""];
    if (salt.length > 8) {
        salt = [salt substringToIndex:8];
    }

    // Signature format = "#{userId}-#{epoch}-#{salt}"
    long      ts              = (long)[NSDate date].timeIntervalSince1970;
    NSString* toSign          = [NSString stringWithFormat:kISNotesSignature,
                                 userId,
                                 ts,
                                 salt];
    NSData*   toSignData      = [toSign dataUsingEncoding:NSUTF8StringEncoding];
    NSData*   signature       = [key signatureForData:toSignData];
    NSString* signatureString = [signature base64EncodedStringWithOptions:0];

    NSString* path            = [NSString stringWithFormat:kISNotesPutDeviceToken,
                                 userId,
                                 ts,
                                 salt,
                                 signatureString];

    NSURL*    URL             = [[self notesAPIServerURL] URLByAppendingPathComponent:path];
    
    NSDictionary* payload = @{
                              @"platform": @"iOS",
                              @"token": token
                              };

    __autoreleasing NSError* error = nil;
    NSData* body = [NSJSONSerialization dataWithJSONObject:payload
                                                   options:0
                                                     error:&error];
    if (error) {
        return nil;
    }
    
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:URL
                                                       cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                   timeoutInterval:kTimeout];
    [req setHTTPMethod:@"POST"];
    [req setHTTPBody:body];
    
    return req;
}

@end
