//
//  UIView+OTMDateAndTimeFormatter.m
//  CarBeacon
//
//  Created by Igor Sales on 2015-10-19.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import "UIView+OTMDateAndTimeFormatter.h"


@implementation UIView (OTMDateAndTimeFormatter)

- (void)formatWithDate:(NSDate*)date
{
    NSDateFormatter* dateFormatter = [NSDateFormatter new];
    
    if ([self respondsToSelector:@selector(monthLabel)]) {
        [dateFormatter setDateFormat:@"MMMM"];
        ((UILabel*)[(id)self monthLabel]).text = [dateFormatter stringFromDate:date];
    }
    
    if ([self respondsToSelector:@selector(dayLabel)]) {
        [dateFormatter setDateFormat:@"dd"];
        ((UILabel*)[(id)self dayLabel]).text = [dateFormatter stringFromDate:date];
    }

    if ([self respondsToSelector:@selector(timeLabel)]) {
        [dateFormatter setDateFormat:@"HH:mm"];
        ((UILabel*)[(id)self timeLabel]).text = [dateFormatter stringFromDate:date];
    }
}

@end
