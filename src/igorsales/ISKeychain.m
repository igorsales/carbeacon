//
//  ISKeychain.m
//  BTConnTest
//
//  Created by Igor Sales on 2015-09-26.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import "ISKeychain.h"
#import "ISPKey.h"

#define IS_LOG_LEVEL IS_LOG_LEVEL_WARN
#import "ISLog.h"


@implementation ISKeychain

#pragma mark - Private

- (SecKeyRef)RSAKeyRefForIdentifier:(NSString*)identifier public:(BOOL)isPublic
{
    OSStatus sanityCheck = noErr;
    SecKeyRef key = nil;
    
    if (isPublic) {
        identifier = [identifier stringByAppendingString:@".public"];
    } else {
        identifier = [identifier stringByAppendingString:@".private"];
    }
    
    NSData* idData = [identifier dataUsingEncoding:NSUTF8StringEncoding];
    
    // Set the key query dictionary.
    NSDictionary * query = @{
                             (__bridge id)kSecClass: (__bridge id)kSecClassKey,
                             (__bridge id)kSecAttrApplicationTag: idData,
                             (__bridge id)kSecAttrKeyType: (__bridge id)kSecAttrKeyTypeRSA,
                             (__bridge id)kSecReturnRef: @(YES)
                             };
    
    // Get the key.
    sanityCheck = SecItemCopyMatching((__bridge CFDictionaryRef)(query), (CFTypeRef*)&key);
    
    if (sanityCheck != noErr) {
        ISLogInfo(@"Cannot retrieve key for %@: %d", identifier, (int)sanityCheck);
        return nil;
    }
    
    return key;
}

- (NSData*)publicKeyStrippedFromHeader:(NSData *)inKey
{
    // Skip ASN.1 public key header
    NSAssert(inKey, @"inKey is nil");
    
    unsigned int len = (unsigned int)inKey.length;
    NSAssert(len > 0, @"Empty key");
    
    uint8_t*   c_key = (uint8_t*)inKey.bytes;
    NSUInteger idx   = 0;
    
    if (c_key[idx++] != 0x30) {
        return nil;
    }
    
    if (c_key[idx] > 0x80) {
        idx += c_key[idx] - 0x80 + 1;
    } else {
        idx++;
    }
    
    // PKCS #1 rsaEncryption szOID_RSA_RSA
    static uint8_t sSeqIOD[] = {
        0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
        0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00
    };

    if (memcmp(&c_key[idx], sSeqIOD, sizeof(sSeqIOD))) {
        return nil;
    }
    
    idx += sizeof(sSeqIOD);
    
    if (c_key[idx++] != 0x03) {
        return nil;
    }

    if (c_key[idx] > 0x80) {
        idx += c_key[idx] - 0x80 + 1;
    } else {
        idx++;
    }
    
    if (c_key[idx++] != '\0') {
        return nil;
    }
    
    // Now make a new NSData from this buffer
    return [NSData dataWithBytes:&c_key[idx] length:len - idx];
}

#pragma mark - Operations

- (NSData*)RSAKeyDataForIdentifier:(NSString*)identifier public:(BOOL)isPublic
{
    OSStatus sanityCheck = noErr;
    CFDataRef keyData = nil;
    
    if (isPublic) {
        identifier = [identifier stringByAppendingString:@".public"];
    } else {
        identifier = [identifier stringByAppendingString:@".private"];
    }
    
    NSData* idData = [identifier dataUsingEncoding:NSUTF8StringEncoding];
    
    // Set the key query dictionary.
    NSDictionary * query = @{
                             (__bridge id)kSecClass: (__bridge id)kSecClassKey,
                             (__bridge id)kSecAttrApplicationTag: idData,
                             (__bridge id)kSecAttrKeyType: (__bridge id)kSecAttrKeyTypeRSA,
                             (__bridge id)kSecReturnData: @(YES)
                             };
    
    // Get the key.
    sanityCheck = SecItemCopyMatching((__bridge CFDictionaryRef)(query), (CFTypeRef*)&keyData);
    
    if (sanityCheck != noErr) {
        ISLogInfo(@"Cannot retrieve key for %@: %d", identifier, (int)sanityCheck);
        return nil;
    }
    
    return CFBridgingRelease(keyData);
}

- (NSString*)PEMForPublicKey:(ISPKey *)publicKey
{
    NSData* keyData = [self RSAKeyDataForIdentifier:publicKey.identifier public:YES];
    
    // PKCS #1 rsaEncryption szOID_RSA_RSA
    NSUInteger keyDataLen = keyData.length;
    uint8_t headerPlusSeqIOD[] = {
        0x30, 0x82, 0x01, 0x22,
        
        // szOID_RSA_RSA
        0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
        0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00,
        
        0x03, 0x82, 0x01, 0x0f, 0x00
    };
    
    keyDataLen += 1; // for the last 0x00 above
    
    NSAssert(keyDataLen > 0xFF, @"keyData must be larger than 0xFF bytes");

    headerPlusSeqIOD[21] = (keyDataLen >> 8) & 0xFF;
    headerPlusSeqIOD[22] = keyDataLen & 0xFF;
    
    keyDataLen += 19; // 20-1 to compensate for the 0x00 above

    NSAssert(keyDataLen > 0xFF, @"keyData must be larger than 0xFF bytes");

    headerPlusSeqIOD[2]  = (keyDataLen >> 8) & 0xFF;
    headerPlusSeqIOD[3]  = keyDataLen & 0xFF;
    
    NSMutableData* newKeyData = [NSMutableData new];
    [newKeyData appendBytes:headerPlusSeqIOD length:sizeof(headerPlusSeqIOD)];
    [newKeyData appendData:keyData];
    
    NSMutableString* pemString = [NSMutableString new];
    [pemString appendString:@"-----BEGIN PUBLIC KEY-----\n"];
    [pemString appendString:[newKeyData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength]];
    [pemString appendString:@"\n-----END PUBLIC KEY-----\n"];
    
    return pemString;
}

- (BOOL)generateKeyPairForIdentifier:(NSString*)identifier
{
    OSStatus sanityCheck = noErr;
    SecKeyRef publicKeyRef = NULL;
    SecKeyRef privateKeyRef = NULL;
    
    NSUInteger keySize = kPKeyNumberOfBits;
    
    NSData* publicTag  = [[identifier stringByAppendingString:@".public"] dataUsingEncoding:NSUTF8StringEncoding];
    NSData* privateTag = [[identifier stringByAppendingString:@".private"] dataUsingEncoding:NSUTF8StringEncoding];
    
    // First delete current keys.
    NSDictionary * queryPublicKey = @{
                                      (__bridge id)kSecClass: (__bridge id)kSecClassKey,
                                      (__bridge id)kSecAttrApplicationTag: publicTag,
                                      (__bridge id)kSecAttrKeyType: (__bridge id)kSecAttrKeyTypeRSA
                                      };

    NSDictionary * queryPrivateKey = @{
                                       (__bridge id)kSecClass: (__bridge id)kSecClassKey,
                                       (__bridge id)kSecAttrApplicationTag: privateTag,
                                       (__bridge id)kSecAttrKeyType: (__bridge id)kSecAttrKeyTypeRSA
                                       };
    
    // Delete the private key.
    sanityCheck = SecItemDelete((__bridge CFDictionaryRef)queryPrivateKey);
    
    // Delete the public key.
    sanityCheck = SecItemDelete((__bridge CFDictionaryRef)queryPublicKey);
    
    // Set the private key dictionary.
    NSDictionary* prvKeyAttr = @{
                                 (__bridge id)kSecAttrIsPermanent: @(YES),
                                 (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleAlways,
                                 (__bridge id)kSecAttrApplicationTag: privateTag
                                 };
    
    // Set the public key dictionary.
    NSDictionary* pubKeyAttr = @{
                                 (__bridge id)kSecAttrIsPermanent: @(YES),
                                 (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleAlways,
                                 (__bridge id)kSecAttrApplicationTag: publicTag
                                 };

    // Set top level dictionary for the keypair.
    NSDictionary* keyPairAttr = @{
                                  (__bridge id)kSecAttrKeyType: (__bridge id)kSecAttrKeyTypeRSA,
                                  (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleAlways,
                                  (__bridge id)kSecAttrKeySizeInBits: @(keySize),
                                  (__bridge id)kSecPrivateKeyAttrs: prvKeyAttr,
                                  (__bridge id)kSecPublicKeyAttrs: pubKeyAttr
                                  };
    

    
    // SecKeyGeneratePair returns the SecKeyRefs just for educational purposes.
    sanityCheck = SecKeyGeneratePair((__bridge CFDictionaryRef)keyPairAttr, &publicKeyRef, &privateKeyRef);
    if(sanityCheck != noErr || !publicKeyRef || !privateKeyRef) {
        ISLogError(@"Something really bad went wrong with generating the key pair.");
    }
    
    return sanityCheck == noErr;
}

- (ISPKey*)keyPairForIdentifier:(NSString*)identifier createIfNil:(BOOL)shouldCreate
{
    SecKeyRef pubKey = [self RSAKeyRefForIdentifier:identifier public:YES];
    SecKeyRef prvKey = [self RSAKeyRefForIdentifier:identifier public:NO];
    
    if (shouldCreate && (!pubKey || !prvKey)) {
        [self generateKeyPairForIdentifier:identifier];

        pubKey = [self RSAKeyRefForIdentifier:identifier public:YES];
        prvKey = [self RSAKeyRefForIdentifier:identifier public:NO];
    }
    
    if (pubKey) {
        return [[ISPKey alloc] initWithIdentifier:identifier
                                       privateKey:prvKey
                                        publicKey:pubKey];
    }
    
    return nil;
}

- (ISPKey*)addPeerPublicKeyWithIdentifier:(NSString *)identifier keyBits:(NSData *)publicKeyData
{
    OSStatus sanityCheck = noErr;
    CFTypeRef peerKeyRef = nil;
    SecKeyRef keyRef = nil;
    
    NSData* strippedPubKeyData = [self publicKeyStrippedFromHeader:publicKeyData];
    if (strippedPubKeyData) {
        publicKeyData = strippedPubKeyData;
    }
    
    NSString* publicIdentifier = [identifier stringByAppendingString:@".public"];
    
    NSData* keyIdTag = [publicIdentifier dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary* peerPublicKeyAttr = @{
                                        (__bridge id)kSecClass: (__bridge id)kSecClassKey,
                                        (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleAlways,
                                        (__bridge id)kSecAttrKeyType: (__bridge id)kSecAttrKeyTypeRSA,
                                        (__bridge id)kSecAttrApplicationTag: keyIdTag,
                                        (__bridge id)kSecValueData: publicKeyData,
                                        (__bridge id)kSecReturnPersistentRef: @(YES),
                                        };
    
    sanityCheck = SecItemAdd((__bridge CFDictionaryRef) peerPublicKeyAttr, (CFTypeRef *)&peerKeyRef);

    if (sanityCheck != noErr) {
        ISLogError(@"Problem adding the peer public key to the keychain, OSStatus == %d.", (int)sanityCheck);
        return nil;
    }
    
    /*NSDictionary* secKeyQuery = @{
                                  (__bridge id)kSecClass: (__bridge id)kSecClassKey,
                                  (__bridge id)kSecAttrKeyType: (__bridge id)kSecAttrKeyTypeRSA,
                                  (__bridge id)kSecAttrApplicationTag: keyIdTag,
                                  (__bridge id)kSecReturnRef: @(YES)
                                  };
    
    // Get the persistent key reference.
    sanityCheck = SecItemCopyMatching((__bridge CFDictionaryRef)secKeyQuery, (CFTypeRef *)&keyRef);
    
    if (sanityCheck != noErr) {
        NSLog(@"Problem retrieving public key ref from persistent ref, OSStatus == %d.", (int)sanityCheck);
        return nil;
    }*/
    
    /* TODO: Ponder if this should be done
    if (sanityCheck == errSecDuplicateItem) {
        [self removePeerPublicKeyWithIdentifier:identifier];
        sanityCheck = SecItemAdd((__bridge CFDictionaryRef) peerPublicKeyAttr, (CFTypeRef *)&peerKeyRef);
        
        if (sanityCheck != noErr) {
            NSLog(@"Problem adding the peer public key to the keychain even after removing, OSStatus == %d.", (int)sanityCheck);
        }
    }*/
    
    CFRelease(peerKeyRef);
    
    keyRef = [self RSAKeyRefForIdentifier:identifier public:YES];
    if (!peerKeyRef) {
        ISLogError(@"Problem retrieving public key ref");
        return nil;
    }
    
    ISPKey* pkey = [[ISPKey alloc] initWithIdentifier:identifier publicKey:keyRef];

    return pkey;
}

- (void)removePeerPublicKeyWithIdentifier:(NSString *)identifier
{
    OSStatus sanityCheck = noErr;
    
    identifier = [identifier stringByAppendingString:@".public"];
    
    NSData* keyIdTag = [identifier dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary* peerPublicKeyAttr = @{
                                        (__bridge id)kSecClass: (__bridge id)kSecClassKey,
                                        (__bridge id)kSecAttrKeyType: (__bridge id)kSecAttrKeyTypeRSA,
                                        (__bridge id)kSecAttrApplicationTag: keyIdTag
                                        };
    
    sanityCheck = SecItemDelete((__bridge CFDictionaryRef) peerPublicKeyAttr);
    
    if(sanityCheck != noErr && sanityCheck != errSecItemNotFound) {
        ISLogInfo(@"Problem deleting the peer public key to the keychain, OSStatus == %d.", (int)sanityCheck);
    }
}

- (void)setString:(NSString *)value forKey:(NSString *)key
{
    NSAssert(key, @"Key cannot be nil");
    OSStatus r = noErr;

    NSData* keyTag = [key dataUsingEncoding:NSUTF8StringEncoding];

    // To update, we must delete anyhow
    NSDictionary * queryPublicKey = @{
                                      (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                                      (__bridge id)kSecAttrService: keyTag,
                                      (__bridge id)kSecReturnRef: @(YES)
                                      };
    
    r = SecItemDelete((__bridge CFTypeRef)queryPublicKey);
    if (r != noErr && r != errSecItemNotFound) {
        ISLogInfo(@"Cannot delete string for key %@", key);
    }

    if (value) {
        CFTypeRef* result = nil;

        NSData* valueData = [value dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary * queryPublicKey = @{
                                          (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                                          (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleAlways,
                                          (__bridge id)kSecAttrService: keyTag,
                                          (__bridge id)kSecValueData: valueData,
                                          (__bridge id)kSecReturnRef: @(YES)
                                          };

        if (noErr != (r = SecItemAdd((__bridge CFDictionaryRef)queryPublicKey, result))) {
            ISLogInfo(@"Cannot retrieve generic password for key");
        }
        
        if (!result) {
            ISLogInfo(@"No reference returned");
        }

        CFBridgingRelease(result);
    }
}

- (NSString*)stringForKey:(NSString *)key
{
    NSAssert(key, @"Key cannot be nil");
    OSStatus r = noErr;

    NSData* keyTag = [key dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary * queryPublicKey = @{
                                      (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                                      (__bridge id)kSecAttrService: keyTag,
                                      (__bridge id)kSecReturnData: @(YES)
                                      };

    CFDataRef keyDataRef = nil;
    if (noErr != (r = SecItemCopyMatching((__bridge CFTypeRef)queryPublicKey, (CFTypeRef*)&keyDataRef))) {
        ISLogInfo(@"Cannot retrieve string for key %@", key);
    }
    
    NSData* keyData = CFBridgingRelease(keyDataRef);

    if (keyData) {
        return [[NSString alloc] initWithData:keyData encoding:NSUTF8StringEncoding];
    }
    
    return nil;
}

@end
