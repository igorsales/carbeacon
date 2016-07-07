//
//  OTMBubbleCalendarView.m
//  CarBeacon
//
//  Created by Igor Sales on 2015-11-05.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import "OTMBubbleCalendarView.h"

@implementation OTMBubbleCalendarView

#pragma mark - Accessors

- (CGFloat)animationVelocity
{
    return 0.87;
}

- (CGFloat)animationDuration
{
    return 0.36;
}

- (CGFloat)animationDamping
{
    return 0.5;
}

#pragma mark - Private

- (CGFloat)animationDurationForStage:(NSInteger)stage
{
    CGFloat step = self.animationDuration / 3.0;

    return (stage - 1) * step + step * 0.85;
}

#pragma mark - Operations

- (void)showAnimated:(BOOL)animated withCompletionBlock:(void (^)())block
{
    if (!block) {
        block = ^{};
    }

    self.smallBubbleView.alpha  = 0.0;
    self.mediumBubbleView.alpha = 0.0;
    self.cloudView.alpha        = 0.0;
    
    CGFloat initialVelocity = self.animationVelocity;
    CGFloat duration        = animated ? self.animationDuration : 0.0;
    CGFloat delay1          = [self animationDurationForStage:1];
    CGFloat delay2          = [self animationDurationForStage:2];
    CGFloat damping         = self.animationDamping;

    CGAffineTransform xform = CGAffineTransformMakeScale(initialVelocity, initialVelocity);
    self.smallBubbleView.transform  = xform;
    self.mediumBubbleView.transform = xform;
    self.cloudView.transform        = xform;
    
    // small bubble animation
    [UIView animateWithDuration:duration
                          delay:0.0
         usingSpringWithDamping:damping
          initialSpringVelocity:initialVelocity
                        options:0
                     animations:^{
                         self.smallBubbleView.transform = CGAffineTransformIdentity;
                     }
                     completion:nil];
    
    [UIView animateWithDuration:duration
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:initialVelocity
                        options:0
                     animations:^{
                         self.smallBubbleView.alpha = 1.0;
                     } completion:nil];

    // medium bubble animation
    [UIView animateWithDuration:duration
                          delay:delay1
         usingSpringWithDamping:damping
          initialSpringVelocity:initialVelocity
                        options:0
                     animations:^{
                         self.mediumBubbleView.transform = CGAffineTransformIdentity;
                     }
                     completion:nil];
    
    [UIView animateWithDuration:duration
                          delay:delay1
         usingSpringWithDamping:1.0
          initialSpringVelocity:initialVelocity
                        options:0
                     animations:^{
                         self.mediumBubbleView.alpha = 1.0;
                     } completion:nil];

    // cloud animation
    [UIView animateWithDuration:duration
                          delay:delay2
         usingSpringWithDamping:damping
          initialSpringVelocity:initialVelocity
                        options:0
                     animations:^{
                         self.cloudView.transform = CGAffineTransformIdentity;
                     }
                     completion:nil];
    
    [UIView animateWithDuration:duration
                          delay:delay2
         usingSpringWithDamping:1.0
          initialSpringVelocity:initialVelocity
                        options:0
                     animations:^{
                         self.cloudView.alpha = 1.0;
                     } completion:^(BOOL finished) { block(); } ];
}

- (void)hideAnimated:(BOOL)animated withCompletionBlock:(void (^)())block
{
    if (!block) {
        block = ^{};
    }
    
    CGFloat initialVelocity = self.animationVelocity;
    CGFloat duration        = animated ? self.animationDuration : 0.0;
    CGFloat delay1          = [self animationDurationForStage:1];
    CGFloat delay2          = [self animationDurationForStage:2];

    CGAffineTransform xform = CGAffineTransformMakeScale(initialVelocity, initialVelocity);
    
    // cloud animation
    [UIView animateWithDuration:duration
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:initialVelocity
                        options:0
                     animations:^{
                         self.cloudView.transform = xform;
                     }
                     completion:nil];
    
    [UIView animateWithDuration:duration
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:initialVelocity
                        options:0
                     animations:^{
                         self.cloudView.alpha = 0.0;
                     } completion:nil];

    // medium bubble animation
    [UIView animateWithDuration:duration
                          delay:delay1
         usingSpringWithDamping:1.0
          initialSpringVelocity:initialVelocity
                        options:0
                     animations:^{
                         self.mediumBubbleView.transform = xform;
                     }
                     completion:nil];
    
    [UIView animateWithDuration:duration
                          delay:delay1
         usingSpringWithDamping:1.0
          initialSpringVelocity:initialVelocity
                        options:0
                     animations:^{
                         self.mediumBubbleView.alpha = 0.0;
                     } completion:nil];

    // small bubble animation
    [UIView animateWithDuration:duration
                          delay:delay2
         usingSpringWithDamping:1.0
          initialSpringVelocity:initialVelocity
                        options:0
                     animations:^{
                         self.smallBubbleView.transform = xform;
                     }
                     completion:nil];
    
    [UIView animateWithDuration:duration
                          delay:delay2
         usingSpringWithDamping:1.0
          initialSpringVelocity:initialVelocity
                        options:0
                     animations:^{
                         self.smallBubbleView.alpha = 0.0;
                     } completion:^(BOOL finished) { block(); }];
}

@end
