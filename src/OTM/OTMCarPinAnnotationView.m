//
//  OTMCarPinAnnotationView.m
//  CarBeacon
//
//  Created by Igor Sales on 2015-10-28.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import "OTMCarPinAnnotationView.h"
#import "OTMBubbleCalendarView.h"

#import <BLEKit/UINib+NibView.h>

@interface OTMCarPinAnnotationView()

@property (nonatomic, weak) OTMBubbleCalendarView* bubbleView;

@end

@implementation OTMCarPinAnnotationView

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    if (selected) {
        if (!self.bubbleView) {
            OTMBubbleCalendarView* view = (OTMBubbleCalendarView*)[UINib viewFromNibNamed:@"ThoughtBubble" bundle:nil];
            
            CGPoint offset = self.calloutOffset;
            
            offset.x -= view.center.x;
            
            // shift by half the small bubble
            offset.x += view.smallBubbleView.frame.origin.x + view.smallBubbleView.frame.size.width * 0.5;
            
            CGRect frame = view.bounds;
            frame.origin.x = -offset.x;
            frame.origin.y = - frame.size.height;
            
            view.frame = frame;
            
            
            view.timeLabel.text = self.annotation.subtitle;
            
            NSArray* lines = [self.annotation.title componentsSeparatedByString:@" "];
            if (lines.count > 0) {
                view.monthLabel.text = lines[0];
                if (lines.count > 1) {
                    view.dayLabel.text = lines[1];
                }
            }
            
            [self addSubview:view];
            self.bubbleView = view;
            
            [self.bubbleView showAnimated:animated withCompletionBlock:nil];
        }
    } else {
        if (self.bubbleView) {
            [self.bubbleView hideAnimated:animated withCompletionBlock:^{
                [self.bubbleView removeFromSuperview];
            }];
            self.bubbleView = nil;
        }
    }
}

- (void)setAccuracy:(CGFloat)accuracy onMapView:(MKMapView*)mapView animated:(BOOL)animated
{
    if (accuracy > 0.0) {
        self.accuracyView.hidden = NO;
        
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self.annotation.coordinate,
                                                                       accuracy,
                                                                       accuracy);
        
        CGRect frame = [mapView convertRegion:region toRectToView:nil];
        
        CGFloat halfWidth = frame.size.width / 2.0;
        CGFloat halfHeight = frame.size.height / 2.0;
        
        halfWidth  = MAX(halfWidth, 8.0);
        halfHeight = MAX(halfHeight, 8.0);

        frame.size = CGSizeMake(2.0 * halfWidth, 2.0 * halfHeight);

        frame.origin.x = self.accuracyView.center.x - halfWidth;
        frame.origin.y = self.accuracyView.center.y - halfHeight;

        self.accuracyView.layer.cornerRadius = MIN(halfWidth, halfHeight);
        self.accuracyView.layer.borderColor  = [self.accuracyView.tintColor colorWithAlphaComponent:0.36].CGColor;
        self.accuracyView.layer.borderWidth  = 1.3;

        self.accuracyView.backgroundColor = [self.accuracyView.tintColor colorWithAlphaComponent:0.13];
        
        [UIView animateWithDuration:0.3
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.accuracyView.frame = frame;
                         }
                         completion:nil];
    } else {
        self.accuracyView.hidden = YES;
    }
}

@end
