//
//  ISPKey.m
//  BTConnTest
//
//  Created by Igor Sales on 2015-09-26.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import "ISPKey.h"
#import "NSData+Digest.h"

#import <Security/Security.h>
#import <CommonCrypto/CommonCrypto.h>
#import <AssertMacros.h>

#define IS_LOG_LEVEL IS_LOG_LEVEL_WARN
#import "ISLog.h"


// Global constants for padding schemes.
#define kPKCS1                  11
#define kTypeOfWrapPadding      kSecPaddingPKCS1

@interface ISPKey()

@end

@implementation ISPKey

#pragma mark - Setup/teardown

- (id)initWithIdentifier:(NSString *)identifier privateKey:(SecKeyRef)key publicKey:(SecKeyRef)pubKey
{
    if ((self = [super init])) {
        _identifier = [identifier copy];
        _privateKey = key;
        _publicKey  = pubKey;
    }

    return self;
}

- (id)initWithIdentifier:(NSString *)identifier publicKey:(SecKeyRef)pubKey
{
    return [self initWithIdentifier:identifier privateKey:nil publicKey:pubKey];
}

- (void)dealloc
{
    if (_privateKey) {
        CFRelease(_privateKey);
    }

    if (_publicKey) {
        CFRelease(_publicKey);
    }
}

#pragma mark - Private

- (NSData*)randomSymmetricKey
{
    OSStatus sanityCheck = noErr;
    
    // Allocate some buffer space. I don't trust calloc.
    uint8_t* symmetricKey = malloc( kPKeyCipherKeySize * sizeof(uint8_t) );
    
    NSAssert(symmetricKey != NULL, @"Problem allocating buffer space for symmetric key generation.");
    
    memset((void *)symmetricKey, 0x0, kPKeyCipherKeySize);
    
    sanityCheck = SecRandomCopyBytes(kSecRandomDefault, kPKeyCipherKeySize, symmetricKey);
    NSAssert(sanityCheck == noErr, @"Problem generating the symmetric key, OSStatus == %d.", (int)sanityCheck);
    
    NSData* key = [[NSData alloc] initWithBytes:(const void *)symmetricKey length:kPKeyCipherKeySize];
    
    free(symmetricKey);
    
    return key;
}

- (NSData *)encryptedSymmetricKey:(NSData *)symmetricKey withKeyRef:(SecKeyRef)RSAKey
{
    OSStatus sanityCheck = noErr;
    size_t cipherBufferSize = 0;
    size_t keyBufferSize = 0;
    
    NSAssert(symmetricKey, @"Symmetric key parameter is nil." );
    NSAssert(RSAKey, @"Key parameter is nil." );
    
    NSData * cipher = nil;
    uint8_t * cipherBuffer = NULL;
    
    // Calculate the buffer sizes.
    cipherBufferSize = SecKeyGetBlockSize(RSAKey);
    keyBufferSize = symmetricKey.length;
    
    if (kTypeOfWrapPadding == kSecPaddingNone) {
        NSAssert(keyBufferSize <= cipherBufferSize, @"Nonce integer is too large and falls outside multiplicative group.");
    } else {
        NSAssert(keyBufferSize <= (cipherBufferSize - 11), @"Nonce integer is too large and falls outside multiplicative group.");
    }
    
    // Allocate some buffer space.
    cipherBuffer = malloc( cipherBufferSize * sizeof(uint8_t) );
    memset((void *)cipherBuffer, 0x0, cipherBufferSize);
    
    // Encrypt using the public key.
    sanityCheck = SecKeyEncrypt(RSAKey,
                                kTypeOfWrapPadding,
                                (const uint8_t *)symmetricKey.bytes,
                                keyBufferSize,
                                cipherBuffer,
                                &cipherBufferSize
                                );
    
    if (sanityCheck != noErr) {
        ISLogInfo(@"Error encrypting, OSStatus == %d.", (int)sanityCheck);
    } else {
        // Build up cipher text blob.
        cipher = [NSData dataWithBytes:(const void *)cipherBuffer length:(NSUInteger)cipherBufferSize];
    }
    
    if (cipherBuffer) {
        free(cipherBuffer);
    }
    
    return cipher;
}

- (NSData*)decryptedSymmetricKey:(NSData *)wrappedSymmetricKey withKeyRef:(SecKeyRef)RSAKey
{
    OSStatus sanityCheck = noErr;
    size_t cipherBufferSize = 0;
    size_t keyBufferSize = 0;
    
    NSData * key = nil;
    uint8_t * keyBuffer = nil;
    
    NSAssert(RSAKey, @"No RSA key specified.");
    
    // Calculate the buffer sizes.
    cipherBufferSize = SecKeyGetBlockSize(RSAKey);
    keyBufferSize = [wrappedSymmetricKey length];
    
    NSAssert(keyBufferSize <= cipherBufferSize, @"Encrypted nonce is too large and falls outside multiplicative group.");
    
    // Allocate some buffer space. I don't trust calloc.
    keyBuffer = malloc( keyBufferSize * sizeof(uint8_t) );
    memset((void *)keyBuffer, 0x0, keyBufferSize);
    
    // Decrypt using the private key.
    sanityCheck = SecKeyDecrypt(RSAKey,
                                kTypeOfWrapPadding,
                                (const uint8_t *)wrappedSymmetricKey.bytes,
                                cipherBufferSize,
                                keyBuffer,
                                &keyBufferSize
                                );
    
    if (sanityCheck != noErr) {
        ISLogInfo(@"Error decrypting, OSStatus == %d.", (int)sanityCheck);
    } else {
        // Build up plain text blob.
        key = [NSData dataWithBytes:(const void *)keyBuffer length:(NSUInteger)keyBufferSize];
    }
    
    if (keyBuffer) {
        free(keyBuffer);
    }
    
    return key;
}

- (NSData*)doCipherData:(NSData *)inData key:(NSData *)symmetricKey context:(CCOperation)encryptOrDecrypt
{
    CCCryptorStatus ccStatus = kCCSuccess;
    // Symmetric crypto reference.
    CCCryptorRef thisEncipher = NULL;
    // Cipher Text container.
    NSData * outData = nil;
    // Pointer to output buffer.
    uint8_t * bufferPtr = NULL;
    // Total size of the buffer.
    size_t bufferPtrSize = 0;
    // Remaining bytes to be performed on.
    size_t remainingBytes = 0;
    // Number of bytes moved to buffer.
    size_t movedBytes = 0;
    // Length of plainText buffer.
    size_t plainTextBufferSize = 0;
    // Placeholder for total written.
    size_t totalBytesWritten = 0;
    // A friendly helper pointer.
    uint8_t * ptr;
    // Padding option
    CCOptions pkcs7 = kCCOptionPKCS7Padding;
    
    // Initialization vector; dummy in this case 0's.
    uint8_t iv[kPKeyCipherBlockSize];
    memset((void *) iv, 0x0, (size_t) sizeof(iv));
    
    NSAssert(inData, @"PlainText object cannot be nil." );
    NSAssert(inData.length > 0, @"Empty data passed in." );
    NSAssert(symmetricKey, @"Symmetric key object cannot be nil." );
    NSAssert(pkcs7, @"CCOptions * pkcs7 cannot be NULL." );
    NSAssert(symmetricKey.length == kPKeyCipherKeySize, @"Disjoint choices for key size." );

    do {
        plainTextBufferSize = inData.length;
        
        // We don't want to toss padding on if we don't need to
        if (encryptOrDecrypt == kCCEncrypt) {
            if ((plainTextBufferSize % kPKeyCipherBlockSize) == 0) {
                pkcs7 = 0x0000;
            } else {
                pkcs7 = kCCOptionPKCS7Padding;
            }
        } else if (encryptOrDecrypt != kCCDecrypt) {
            NSAssert(NO, @"Invalid CCOperation parameter [%d] for cipher context.", encryptOrDecrypt );
        }
        
        // Create and Initialize the crypto reference.
        ccStatus = CCCryptorCreate(encryptOrDecrypt,
                                   kCCAlgorithmAES128,
                                   pkcs7,
                                   (const void *)symmetricKey.bytes,
                                   kPKeyCipherKeySize,
                                   (const void *)iv,
                                   &thisEncipher
                                   );
        
        if (ccStatus != kCCSuccess) {
            ISLogError(@"Problem creating the context, ccStatus == %d.", ccStatus);
            break;
        }
        
        // Calculate byte block alignment for all calls through to and including final.
        bufferPtrSize = CCCryptorGetOutputLength(thisEncipher, plainTextBufferSize, true);
        
        // Allocate buffer.
        bufferPtr = malloc( bufferPtrSize * sizeof(uint8_t) );
        
        // Zero out buffer.
        memset((void *)bufferPtr, 0x0, bufferPtrSize);
        
        // Initialize some necessary book keeping.
        ptr = bufferPtr;
        
        // Set up initial size.
        remainingBytes = bufferPtrSize;
        
        // Actually perform the encryption or decryption.
        ccStatus = CCCryptorUpdate(thisEncipher,
                                   (const void *)inData.bytes,
                                   plainTextBufferSize,
                                   ptr,
                                   remainingBytes,
                                   &movedBytes
                                   );
        
        if (ccStatus != kCCSuccess) {
            ISLogError(@"Problem with CCCryptorUpdate, ccStatus == %d.", ccStatus);
            break;
        }
        
        // Handle book keeping.
        ptr += movedBytes;
        remainingBytes -= movedBytes;
        totalBytesWritten += movedBytes;
        
        // Finalize everything to the output buffer.
        ccStatus = CCCryptorFinal(thisEncipher,
                                  ptr,
                                  remainingBytes,
                                  &movedBytes
                                  );

        totalBytesWritten += movedBytes;

        if (ccStatus != kCCSuccess) {
            ISLogError(@"Problem with encipherment ccStatus == %d", ccStatus);
            break;
        }

        outData = [NSData dataWithBytes:(const void *)bufferPtr length:(NSUInteger)totalBytesWritten];
    } while(0);

    if (thisEncipher) {
        (void) CCCryptorRelease(thisEncipher);
        thisEncipher = NULL;
    }
    
    if (bufferPtr) {
        free(bufferPtr);
    }
    
    return outData;
    
    /*
     Or the corresponding one-shot call:
     
     ccStatus = CCCrypt(    encryptOrDecrypt,
     kCCAlgorithmAES128,
     typeOfSymmetricOpts,
     (const void *)[self getSymmetricKeyBytes],
     kChosenCipherKeySize,
     iv,
     (const void *) [plainText bytes],
     plainTextBufferSize,
     (void *)bufferPtr,
     bufferPtrSize,
     &movedBytes
     );
     */
}

#pragma mark - Operations

- (NSData*)signatureForData:(NSData*)data
{
    if (!self.privateKey) {
        return nil;
    }

    OSStatus sanityCheck = noErr;
    NSData * signedHash = nil;
    
    uint8_t * signedHashBytes = NULL;
    size_t signedHashBytesSize = 0;
    
    signedHashBytesSize = SecKeyGetBlockSize(self.privateKey);
    
    // Malloc a buffer to hold signature.
    signedHashBytes = malloc( signedHashBytesSize * sizeof(uint8_t) );
    memset((void *)signedHashBytes, 0x0, signedHashBytesSize);
    
    NSData* SHA256Hash = [data SHA256Hash];
    
    // Sign the SHA256 hash.
    sanityCheck = SecKeyRawSign(self.privateKey,
                                kSecPaddingPKCS1SHA256,
                                (const uint8_t *)SHA256Hash.bytes,
                                SHA256Hash.length,
                                (uint8_t *)signedHashBytes,
                                &signedHashBytesSize
                                );
    
    if (sanityCheck != noErr) {
        ISLogInfo(@"Problem signing the SHA1 hash, OSStatus == %d.", (int)sanityCheck);
    } else if (signedHashBytes) {
        // Build up signed SHA1 blob.
        signedHash = [NSData dataWithBytes:(const void *)signedHashBytes length:(NSUInteger)signedHashBytesSize];
        
        free(signedHashBytes);
    }
    
    return signedHash;
}

- (BOOL)verifySignature:(NSData *)signature onData:(NSData*)data
{
    size_t signedHashBytesSize = 0;
    OSStatus sanityCheck = noErr;
    
    // Get the size of the assymetric block.
    signedHashBytesSize = SecKeyGetBlockSize(self.publicKey);
    
    NSData* SHA256Hash = [data SHA256Hash];
    NSAssert(SHA256Hash.length == kPKeyDigestLength, @"Invalid hash size");
    
    if (signature.length != signedHashBytesSize) {
        return NO;
    }
    
    sanityCheck = SecKeyRawVerify(self.publicKey,
                                  kSecPaddingPKCS1SHA256,
                                  (const uint8_t *)SHA256Hash.bytes,
                                  kPKeyDigestLength,
                                  (const uint8_t *)signature.bytes,
                                  signedHashBytesSize
                                  );
    
    return (sanityCheck == noErr) ? YES : NO;
}

- (NSData*)encryptedData:(NSData*)decryptedData
{
    NSData*   symmKey        = [self randomSymmetricKey];
    NSData*   ciphered       = [self doCipherData:decryptedData key:symmKey context:kCCEncrypt];
    NSData*   cipheredKey    = [self encryptedSymmetricKey:symmKey withKeyRef:self.publicKey];
    NSString* keyString      = [cipheredKey base64EncodedStringWithOptions:0];
    NSString* cipheredString = [ciphered base64EncodedStringWithOptions:0];
    
    NSString* payload = [NSString stringWithFormat:@"v1.0\nKEY:%@\n%@", keyString, cipheredString];
    
    return [payload dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSData*)decryptedData:(NSData*)encryptedData
{
    NSString* payload = [[NSString alloc] initWithData:encryptedData encoding:NSUTF8StringEncoding];

    if ([payload hasPrefix:@"v1.0\nKEY:"]) {
        NSRange keyLineBreak = [payload rangeOfString:@"\n" options:0 range:NSMakeRange(9, payload.length-9)];
        NSString* keyString  = [payload substringWithRange:NSMakeRange(9, keyLineBreak.location - 9)];
        
        if (payload.length < 9 + keyString.length + 1) {
            ISLogInfo(@"No payload");
            return nil;
        }
        
        NSString* cipheredString = [payload substringWithRange:NSMakeRange(9+keyString.length+1, payload.length-(9+keyString.length+1))];

        NSData* cipheredKey = [[NSData alloc] initWithBase64EncodedString:keyString options:0];
        NSData* ciphered    = [[NSData alloc] initWithBase64EncodedString:cipheredString options:0];

        NSData* symmKey = [self decryptedSymmetricKey:cipheredKey withKeyRef:self.privateKey];

        if (symmKey) {
            return [self doCipherData:ciphered key:symmKey context:kCCDecrypt];
        } else {
            ISLogInfo(@"Symmetric key not found, cannot decrypt");
        }
    }
    
    return nil;
}

@end
