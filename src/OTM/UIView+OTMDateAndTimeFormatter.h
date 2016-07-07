//
//  UIView+OTMDateAndTimeFormatter.h
//  CarBeacon
//
//  Created by Igor Sales on 2015-10-19.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OTMDateAndTimeFormatter <NSObject>

@property (nonatomic, readonly) UILabel* monthLabel;
@property (nonatomic, readonly) UILabel* dayLabel;
@property (nonatomic, readonly) UILabel* timeLabel;

@end

@interface UIView (OTMDateAndTimeFormatter)

- (void)formatWithDate:(NSDate*)date;

@end
