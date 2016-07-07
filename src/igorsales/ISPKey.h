//
//  ISPKey.h
//  BTConnTest
//
//  Created by Igor Sales on 2015-09-26.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kPKeyNumberOfBits     (2048)
#define kPKeyCipherBlockSize  kCCBlockSizeAES128
#define kPKeyCipherKeySize    kCCKeySizeAES128
#define kPKeyDigestLength     CC_SHA256_DIGEST_LENGTH

@interface ISPKey : NSObject

@property (nonatomic, readonly) NSString* identifier;
@property (nonatomic, readonly) SecKeyRef publicKey;
@property (nonatomic, readonly) SecKeyRef privateKey;

- (id)initWithIdentifier:(NSString*)identifier privateKey:(SecKeyRef)keyData publicKey:(SecKeyRef)pubKeyData;
- (id)initWithIdentifier:(NSString*)identifier publicKey:(SecKeyRef)pubKeyData;

- (NSData*)signatureForData:(NSData*)data;
- (BOOL)verifySignature:(NSData *)signature onData:(NSData*)data;
- (NSData*)encryptedData:(NSData*)decryptedData;
- (NSData*)decryptedData:(NSData*)encryptedData;

@end
