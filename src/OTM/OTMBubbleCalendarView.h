//
//  OTMBubbleCalendarView.h
//  CarBeacon
//
//  Created by Igor Sales on 2015-11-05.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OTMBubbleCalendarView : UIView

@property (nonatomic, weak) IBOutlet UIImageView* smallBubbleView;
@property (nonatomic, weak) IBOutlet UIImageView* mediumBubbleView;
@property (nonatomic, weak) IBOutlet UIView*      cloudView;
@property (nonatomic, weak) IBOutlet UILabel*     monthLabel;
@property (nonatomic, weak) IBOutlet UILabel*     dayLabel;
@property (nonatomic, weak) IBOutlet UILabel*     timeLabel;

- (void)showAnimated:(BOOL)animated withCompletionBlock:(void(^)())block;
- (void)hideAnimated:(BOOL)animated withCompletionBlock:(void(^)())block;

@end
