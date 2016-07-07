//
//  NSURLRequest+NotesAPI.h
//  BTConnTest
//
//  Created by Igor Sales on 2015-10-01.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ISPKey;

@interface NSURLRequest (NotesAPI)

+ (NSURL*)notesAPIServerURL;
+ (void)setNotesAPIServerURL:(NSURL*)URL;

+ (NSURLRequest*)requestToPingServer;

+ (NSURLRequest*)requestNewUserWithId:(NSString*)userId
                                label:(NSString*)label
                         publicKeyPEM:(NSString*)publicKey;

+ (NSURLRequest*)requestToSendMessage:(NSString*)message
                           fromUserId:(NSString*)fromUserId
                             toUserId:(NSString*)userId
                        signedWithKey:(ISPKey*)key;

+ (NSURLRequest*)requestToRetrieveMessagesForUserId:(NSString*)userId
                                      signedWithKey:(ISPKey*)key;

+ (NSURLRequest*)requestToPutDeviceToken:(NSString*)token
                               forUserId:(NSString*)userId
                           signedWithKey:(ISPKey*)key;

@end
