//
//  ISKeychain.h
//  BTConnTest
//
//  Created by Igor Sales on 2015-09-26.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ISPKey;

@interface ISKeychain : NSObject

- (NSData*)RSAKeyDataForIdentifier:(NSString*)identifier public:(BOOL)isPublic;
- (NSString*)PEMForPublicKey:(ISPKey*)publicKey;
- (BOOL)generateKeyPairForIdentifier:(NSString*)identifier;
- (ISPKey*)keyPairForIdentifier:(NSString*)identifier createIfNil:(BOOL)shouldCreate;
- (ISPKey*)addPeerPublicKeyWithIdentifier:(NSString *)identifier keyBits:(NSData *)publicKeyData;
- (void)removePeerPublicKeyWithIdentifier:(NSString *)identifier;

- (NSString*)stringForKey:(NSString*)key;
- (void)setString:(NSString*)value forKey:(NSString*)key;

@end
