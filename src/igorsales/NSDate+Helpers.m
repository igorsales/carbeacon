//
//  NSDate+Helpers.m
//  CarBeacon
//
//  Created by Igor Sales on 2015-10-19.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import "NSDate+Helpers.h"

@implementation NSDate (Helpers)

- (NSDate*)dateWithoutTime
{
    NSDateComponents *components = [[NSCalendar currentCalendar]
                                    components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay
                                    fromDate:self];

    return [[NSCalendar currentCalendar]
            dateFromComponents:components];
}

@end
