//
//  NSString+URLEncoding.m
//  BTConnTest
//
//  Created by Igor Sales on 2015-10-01.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import "NSString+URLEncoding.h"

static NSDictionary* sURLEncodingLookup = nil;


static NSDictionary* sURLDecodingLookup = nil;


@implementation NSString (URLEncoding)

+ (void)load
{
    static dispatch_once_t sDispatchOnce = 0;
    dispatch_once(&sDispatchOnce, ^{
        sURLEncodingLookup = @{
                               @"/": @"%2F",
                               @"+": @"%2B",
                               @"=": @"%3D",
                               @"%": @"%25",
                               @" ": @"%20"
                               };
        
        sURLDecodingLookup = @{
                               @"%2F": @"/",
                               @"%2f": @"/",
                               @"%2B": @"+",
                               @"%2b": @"+",
                               @"%3D": @"=",
                               @"%3d": @"=",
                               @"%25": @"%",
                               @"%20": @" "
                               };
    });
}

- (NSString*)URLEncodedString
{
    NSMutableString* str = [self mutableCopy];
    
    [sURLEncodingLookup enumerateKeysAndObjectsUsingBlock:^(id strIn, id strOut, BOOL* stop) {
        [str replaceOccurrencesOfString:strIn withString:strOut options:0 range:NSMakeRange(0, str.length)];
    }];
    
    return str;
}

- (NSString*)URLDecodedString
{
    NSMutableString* str = [self mutableCopy];
    
    [sURLDecodingLookup enumerateKeysAndObjectsUsingBlock:^(id strIn, id strOut, BOOL * stop) {
        [str replaceOccurrencesOfString:strIn withString:strOut options:0 range:NSMakeRange(0, str.length)];
    }];
    
    return str;
}

@end
