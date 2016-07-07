//
//  ISKeychainTest.m
//  BTConnTest
//
//  Created by Igor Sales on 2015-09-27.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "ISKeychain.h"
#import "ISPKey.h"

@interface ISKeychainTest : XCTestCase

@property (nonatomic, strong) ISKeychain* keychain;

@end

@implementation ISKeychainTest

- (void)setUp
{
    [super setUp];
    
    self.keychain = [ISKeychain new];
}

- (void)tearDown
{
    self.keychain = nil;

    [super tearDown];
}

- (void)testKeyPairGeneration
{
    NSString* const identifier = @"ca.igorsales.CarBeacon.test";
    
    ISPKey* pkey = nil;
    
    // TODO: Test when API supports deleting the keys
    //pkey = [self.keychain keyPairForIdentifier:identifier createIfNil:NO];
    //XCTAssertNil(pkey);
    
    pkey = [self.keychain keyPairForIdentifier:identifier createIfNil:YES];
    XCTAssertNotNil(pkey);
    XCTAssertEqual(identifier, pkey.identifier);
    XCTAssert(pkey.publicKey  != nil);
    XCTAssert(pkey.privateKey != nil);
}

- (void)testPublicKeyImport
{
    NSString* const identifier = @"ca.igorsales.CarBeacon.testImport";
    
    ISPKey* pkey = nil;
    
    NSString* base64EncodedPubKey = @""
        "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2+aUuQ9RYlXNKTOaOPXe"
        "eKFENPP39ZdGDqTcDpb8yqE1uOKVswWHy9oauYvUn7M/Ii5giut+xzDKuXYgnvGI"
        "qNZI97lWSfhPPFsjDr4+3W9ZS5m8tOVl2i3S7fXIEXyAs6XrRswLoDVyHpNmpqUB"
        "PoGQIEN9ngm2VM3Xy6mEQ0fAg2GeQzOZ+qniMTLIgxXhZsWxJGjdvZuk+d3BJa7V"
        "93QENVgC9KK70HqdjoMHlnXtpshAsycGAdTC57i7p83w9K5ksNmwNcFktc2v6ig8"
        "HuGIPrBGSqiSwsGFQ5dpP9OoJbmTQZGYYTvsUtV58xvd7EJbhys/LVk6UJnVflNM"
        "yQIDAQAB";
    
    NSData* keyData = [[NSData alloc] initWithBase64EncodedString:base64EncodedPubKey options:0];
    
    [self.keychain removePeerPublicKeyWithIdentifier:identifier];
    pkey = [self.keychain addPeerPublicKeyWithIdentifier:identifier keyBits:keyData];
    
    XCTAssertNotNil(pkey);
    XCTAssertEqual(identifier, pkey.identifier);
    XCTAssert(pkey.publicKey  != nil);
    XCTAssert(pkey.privateKey == nil);
    
    // Now try to obtain from key pair
    pkey = [self.keychain keyPairForIdentifier:identifier createIfNil:NO];
    XCTAssert(pkey.publicKey  != nil);
    XCTAssert(pkey.privateKey == nil);

    // Should fail 'cause it's duplicate
    pkey = [self.keychain addPeerPublicKeyWithIdentifier:identifier keyBits:keyData];
    XCTAssertNil(pkey);
    
    NSData* retrievedKeyData = [self.keychain RSAKeyDataForIdentifier:identifier public:YES];
    XCTAssertNotNil(retrievedKeyData);
    XCTAssertTrue(retrievedKeyData.length > 0);

    // Now try to remove and import again
    [self.keychain removePeerPublicKeyWithIdentifier:identifier];
    pkey = [self.keychain keyPairForIdentifier:identifier createIfNil:NO];
    XCTAssertNil(pkey);
    
    pkey = [self.keychain addPeerPublicKeyWithIdentifier:identifier keyBits:retrievedKeyData];
    
    XCTAssertNotNil(pkey);
    XCTAssertEqual(identifier, pkey.identifier);
    XCTAssert(pkey.publicKey  != nil);
    XCTAssert(pkey.privateKey == nil);

    // Should fail 'cause it's duplicate
    pkey = [self.keychain addPeerPublicKeyWithIdentifier:identifier keyBits:keyData];
    XCTAssertNil(pkey);
}

- (void)testVerifySignature
{
    NSString* const identifier = @"ca.igorsales.CarBeacon.testVerify";
    
    ISPKey* pkey = nil;
    
    NSString* base64EncodedPubKey = @""
        "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAt5sAii3zC71R3IHhU2lw"
        "NjCdhT41TwaS41PiufvSrCoUooviDEJosnBmmmqJ9XaMRzEaDyF8WreS+EjMmrY8"
        "LcuaDmr6n6X8XbS0fa+/xWQsVT0LRBQs+MS4PDHlsLwQA6fjcDPgC8yfHheTNypd"
        "W0Sg+jvM1Weu2JdAw2AGp9EDKHXHioo9+xpCj5RHKOz1RsInRvOuEZTZY5k/8Mkg"
        "WLE5xn/B+sDAmbV4Wq/edCODzasbwVPa0mZk3ZYaXkSmeMM5yXEUC9E/B4Niv7A3"
        "CgNEeGQTpLPmhMZJlppgSXbSFb0JdY+NU8nLUcH7hQs5dVuhtSWH35g7CJa97hP4"
        "9QIDAQAB";
    
    NSString* base64EncodedSignature = @""
        "QrwMNzZ5fteSOKrt+8TIaapnhvLQ2dqr2ZlDWQqfKLm91o33iTLF7X0I+Iad"
        "RA31AKizuQGC2vEDqVd0q0hU5whJxZ0XpOtCHuK7HWLPZQViebJijCuXefXB"
        "1Nx/VLYUwCjNBBK4SYyRHVeogY4jr2lGTRzX/LIuJP7VHijpp1SxTNz3AACB"
        "CpTyc28d7UvEhLsGuEBlRCDcCubV8UBN1eUKO2zAlk1l4rFbCdm/HflNBAKY"
        "VjFWT2Io7c/VihBdpMZYHW9SmqBiYRP2CAN13VkKJm45IkzIKakdetPa4Ose"
        "+AedYjUYduRL2M5lpcaWbvBZvT44u6ocGm9o3XFRHQ==";
    
    NSData* keyData   = [[NSData alloc] initWithBase64EncodedString:base64EncodedPubKey options:0];
    NSData* signature = [[NSData alloc] initWithBase64EncodedString:base64EncodedSignature options:0];
    
    [self.keychain removePeerPublicKeyWithIdentifier:identifier];
    pkey = [self.keychain addPeerPublicKeyWithIdentifier:identifier keyBits:keyData];

    NSData* message = [@"This is a simple test" dataUsingEncoding:NSUTF8StringEncoding];
    
    XCTAssertTrue([pkey verifySignature:signature onData:message]);
    
    // Now test an incorrect message
    NSData* badMessage = [@"This is a simple incorrect test" dataUsingEncoding:NSUTF8StringEncoding];
    
    XCTAssertFalse([pkey verifySignature:signature onData:badMessage]);
    
    NSMutableData* falseSignature = [signature mutableCopy];
    uint8_t* bytes = [falseSignature mutableBytes];
    bytes[0] = bytes[0] ^ 0x01;

    XCTAssertFalse([pkey verifySignature:falseSignature onData:message]);
    
    NSData* retrievedKeyData = [self.keychain RSAKeyDataForIdentifier:identifier public:YES];
    XCTAssertNotNil(retrievedKeyData);
    XCTAssertTrue(retrievedKeyData.length > 0);
    
    // Now try to remove and import again
    [self.keychain removePeerPublicKeyWithIdentifier:identifier];
    pkey = [self.keychain keyPairForIdentifier:identifier createIfNil:NO];
    XCTAssertNil(pkey);
    
    XCTAssertTrue(keyData.length != retrievedKeyData.length);
    
    pkey = [self.keychain addPeerPublicKeyWithIdentifier:identifier keyBits:retrievedKeyData];
    
    XCTAssertTrue([pkey verifySignature:signature onData:message]);
}

- (void)testSign
{
    NSString* const identifier = @"ca.igorsales.CarBeacon.testSign";
    
    ISPKey* pkey = nil;
    
    /*NSString* base64EncodedPubKey = @""
        "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAt5sAii3zC71R3IHhU2lw"
        "NjCdhT41TwaS41PiufvSrCoUooviDEJosnBmmmqJ9XaMRzEaDyF8WreS+EjMmrY8"
        "LcuaDmr6n6X8XbS0fa+/xWQsVT0LRBQs+MS4PDHlsLwQA6fjcDPgC8yfHheTNypd"
        "W0Sg+jvM1Weu2JdAw2AGp9EDKHXHioo9+xpCj5RHKOz1RsInRvOuEZTZY5k/8Mkg"
        "WLE5xn/B+sDAmbV4Wq/edCODzasbwVPa0mZk3ZYaXkSmeMM5yXEUC9E/B4Niv7A3"
        "CgNEeGQTpLPmhMZJlppgSXbSFb0JdY+NU8nLUcH7hQs5dVuhtSWH35g7CJa97hP4"
        "9QIDAQAB";
    
    NSString* base64EncodedPrvKey = @""
        "MIIEpAIBAAKCAQEAt5sAii3zC71R3IHhU2lwNjCdhT41TwaS41PiufvSrCoUoovi"
        "DEJosnBmmmqJ9XaMRzEaDyF8WreS+EjMmrY8LcuaDmr6n6X8XbS0fa+/xWQsVT0L"
        "RBQs+MS4PDHlsLwQA6fjcDPgC8yfHheTNypdW0Sg+jvM1Weu2JdAw2AGp9EDKHXH"
        "ioo9+xpCj5RHKOz1RsInRvOuEZTZY5k/8MkgWLE5xn/B+sDAmbV4Wq/edCODzasb"
        "wVPa0mZk3ZYaXkSmeMM5yXEUC9E/B4Niv7A3CgNEeGQTpLPmhMZJlppgSXbSFb0J"
        "dY+NU8nLUcH7hQs5dVuhtSWH35g7CJa97hP49QIDAQABAoIBAFhwgUIOABSXjOb6"
        "aN8U2sg/gqC75lG6iOaXcY7EjiX/3xCs8KWXF3dcTQ/0YZ+rCscAD91Z89x+sHyI"
        "FIYxYattdzeasD5WZcl9UbN5BJbAOdqVHOgeD8uEdnoITutiqxQXuqZBVppYZgzI"
        "rlDUR0O/OwtN4syotL//m2KAzrPmWQcXUo6/i82ia+8kWkvkDhK+P0zqwnx/F9+U"
        "rzdINDHg+KbcnSj76SdHFbq+ecU7lrj6RzjXvkdLszUCYHPUPRjtflqXWzQnbPC4"
        "ti/rXOrtKbxLV1KX54ilgoerTPRixJRMkZBuFzJWgteLXXTe2l1BPiuvzdWvWqmP"
        "zYT/cgECgYEA3Uu9t2GWD8yJ25nrFVHbby/idt1cU51WHyhtsWlM3e6YXNMsWa4j"
        "7d1nFaQJRpLhHf05P/dohXjvYP0NAUyNYxMAOF2T7/ddgLvsrexfXnRUd7k6Oz3W"
        "0/1eJ5+kECRd8jmpQqK1FlfUCxiBVitUrDjW1MSGP8RyTvECbJjwbFkCgYEA1GYf"
        "htVgb/0koXcFXx8YD3DzhkhLEG/SFwOqEwnTXAYERuThc+54Fg0CgVHt64onDYvM"
        "SzhYqAJSFJv7PC57keuUXZv0lDjC4gpoVDhhOGuPwFf4QDhJ+0yGA8Fkb0mwez6t"
        "38KjIPSVLHPI+W13G/6pr+aEmvkL1t7LA/Yvbf0CgYEAwoW5lmDpj6mz5J0/z9XM"
        "lcf5wZKDfdxnv6vCAJkXQF5i//WAnrQ8UPK1kohGvwqNZ9cXY+sOrYTIpvDJZcLs"
        "5ZHmN6XKTL2cK3UFbzy/+D85oKPpU/nfxSiKgzoI9UeCbVHSPwjXNXSup7I6vowI"
        "OfscnJrDh3ofINUp1Fv7usECgYEApUrcWhgQNtbv/OAdRAt0s/+Y5PW5xQ7glpx5"
        "bNuGquTbyzgv5AK/XZm+S1mxKE6ZWcdjs14kUIuNyRAikpEyBTsqeTb3Pap2r2ae"
        "DnzZ3AiJFIzhW0jy+ihxWtbUDG9yclczBSH5xZnRxYhN7R6tRRIIiCWDKP+LoSo9"
        "H9YkzxkCgYB4Wrdx1ZG4HXa5HnXeI5jNi2K4onz1OQ8PpaSeZpjxw3FJdGnUiN7e"
        "9SN55fcBlENYws5KdvpvHbaCJwzA3Moy5V78F2Acqy1Q1tjjE3mZjEZXwDGj57Pl"
        "4mW2FLZT/gbY5eLCVTTv/atWRpZ8UheVdLtFRPpITRF7KfIUxWyVPw==";

    NSData* pubKeyData   = [[NSData alloc] initWithBase64EncodedString:base64EncodedPubKey options:0];
    NSData* prvKeyData   = [[NSData alloc] initWithBase64EncodedString:base64EncodedPrvKey options:0];
    
    {
        OSStatus sanityCheck = noErr;
        CFTypeRef peerKeyRef = nil;
        //SecKeyRef keyRef = nil;

        //NSData* strippedPubKeyData = [self publicKeyStrippedFromHeader:publicKeyData];
        //if (strippedPubKeyData) {
        //    publicKeyData = strippedPubKeyData;
        //}
        
        NSString* privateIdentifier = [identifier stringByAppendingString:@".private"];
        
        NSData* privateTag = [identifier dataUsingEncoding:NSUTF8StringEncoding];
        
        NSDictionary * queryPrivateKey = @{
                                           (__bridge id)kSecClass: (__bridge id)kSecClassKey,
                                           (__bridge id)kSecAttrApplicationTag: privateTag,
                                           (__bridge id)kSecAttrKeyType: (__bridge id)kSecAttrKeyTypeRSA
                                           };
        
        // Delete the private key.
        sanityCheck = SecItemDelete((__bridge CFDictionaryRef)queryPrivateKey);
        
        NSData* keyIdTag = [privateIdentifier dataUsingEncoding:NSUTF8StringEncoding];
        
        NSDictionary* peerPrvKeyAttr = @{
                                            (__bridge id)kSecClass: (__bridge id)kSecClassKey,
                                            (__bridge id)kSecAttrKeyType: (__bridge id)kSecAttrKeyTypeRSA,
                                            (__bridge id)kSecAttrApplicationTag: keyIdTag,
                                            (__bridge id)kSecValueData: prvKeyData,
                                            (__bridge id)kSecReturnPersistentRef: @(YES),
                                        };
        
        sanityCheck = SecItemAdd((__bridge CFDictionaryRef) peerPrvKeyAttr, (CFTypeRef *)&peerKeyRef);
        
        XCTAssertTrue(sanityCheck == noErr || sanityCheck == errSecDuplicateItem,
                      @"Problem adding the peer public key to the keychain, OSStatus == %d.", (int)sanityCheck);
        
        if (sanityCheck == errSecDuplicateItem) {
            sanityCheck = SecItemUpdate((__bridge CFDictionaryRef)(queryPrivateKey), (__bridge CFDictionaryRef)(peerPrvKeyAttr));
            
            XCTAssertTrue(sanityCheck == noErr, @"Problem updating the peer public key to the keychain, OSStatus == %d.", (int)sanityCheck);
        }
    }

    [self.keychain removePeerPublicKeyWithIdentifier:identifier];
    [self.keychain addPeerPublicKeyWithIdentifier:identifier keyBits:pubKeyData];*/
    
    pkey = [self.keychain keyPairForIdentifier:identifier createIfNil:YES];
    XCTAssertNotNil(pkey);
    XCTAssert(pkey.privateKey != nil);
    
    NSData* message = [@"This is a simple test" dataUsingEncoding:NSUTF8StringEncoding];
    NSData* signature = [pkey signatureForData:message];
    
    XCTAssertTrue(signature.length > 0);
    
    XCTAssertTrue([pkey verifySignature:signature onData:message]);
    
    NSData* newMessage = [@"This is a new simple test" dataUsingEncoding:NSUTF8StringEncoding];
    NSData* newSignature = [pkey signatureForData:newMessage];
    
    XCTAssertFalse([pkey verifySignature:signature onData:newMessage]);
    XCTAssertFalse([pkey verifySignature:newSignature onData:message]);
    XCTAssertTrue([pkey verifySignature:newSignature onData:newMessage]);
}

- (void)testCipherAndUncipher
{
    NSString* const identifier = @"ca.igorsales.CarBeacon.testCipher";
    
    ISPKey* pkey = [self.keychain keyPairForIdentifier:identifier createIfNil:YES];
    XCTAssertNotNil(pkey);
    
    NSString* messageIn = @"message in!";
    NSData* messageData = [messageIn dataUsingEncoding:NSUTF8StringEncoding];

    NSData* encrypted = [pkey encryptedData:messageData];
    XCTAssertNotNil(encrypted);
    XCTAssert(encrypted.length);
    
    NSData* decrypted = [pkey decryptedData:encrypted];
    XCTAssertNotNil(decrypted);
    XCTAssert(decrypted.length);
    
    NSString* messageOut = [[NSString alloc] initWithData:decrypted encoding:NSUTF8StringEncoding];
    
    XCTAssertEqualObjects(messageData, decrypted);
    XCTAssertEqualObjects(messageIn, messageOut);
}

- (void)testStringProperties
{
    NSString* const key = @"ca.igorsales.CarBeacon.testStringKey";
    
    [self.keychain setString:nil forKey:key];
    NSString* value = [self.keychain stringForKey:key];
    XCTAssertNil(value);
    
    [self.keychain setString:@"testKey" forKey:key];
    value = [self.keychain stringForKey:key];
    XCTAssertEqualObjects(@"testKey", value);

    [self.keychain setString:@"testKey2" forKey:key];
    value = [self.keychain stringForKey:key];
    XCTAssertEqualObjects(@"testKey2", value);
}

@end
