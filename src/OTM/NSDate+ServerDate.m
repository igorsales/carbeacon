//
//  NSDate+ServerDate.m
//  CarBeacon
//
//  Created by Igor Sales on 2015-10-23.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import "NSDate+ServerDate.h"

static NSDateFormatter* sFrmter = nil;

@implementation NSDate (ServerDate)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sFrmter = [NSDateFormatter new];
        sFrmter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        [sFrmter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSSS ZZZZ"];
        sFrmter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    });
}

+ (NSDate*)dateFromTimestampString:(NSString*)tsString
{
    return [sFrmter dateFromString:tsString];
}

- (NSString*)timestampString
{
    return [sFrmter stringFromDate:self];
}


@end
