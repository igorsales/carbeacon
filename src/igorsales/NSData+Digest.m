//
//  NSData+Digest.m
//  BTConnTest
//
//  Created by Igor Sales on 2015-09-26.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import "NSData+Digest.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>


#define kChosenDigestLength     CC_SHA256_DIGEST_LENGTH


@implementation NSData (Digest)

- (NSData *)SHA256Hash
{
    CC_SHA256_CTX ctx;
    uint8_t * hashBytes = NULL;
    NSData * hash = nil;
    
    // Malloc a buffer to hold hash.
    hashBytes = malloc( kChosenDigestLength * sizeof(uint8_t) );
    memset((void *)hashBytes, 0x0, kChosenDigestLength);
    
    // Initialize the context.
    CC_SHA256_Init(&ctx);
    // Perform the hash.
    CC_SHA256_Update(&ctx, (void *)self.bytes, (CC_LONG)self.length);
    // Finalize the output.
    CC_SHA256_Final(hashBytes, &ctx);
    
    // Build up the SHA256 blob.
    hash = [NSData dataWithBytes:(const void *)hashBytes length:(NSUInteger)kChosenDigestLength];
    
    if (hashBytes) {
        free(hashBytes);
    }
    
    return hash;
}

@end
