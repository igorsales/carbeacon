//
//  ISRevealAndMoveAnimator.m
//  BTConnTest
//
//  Created by Igor Sales on 2015-09-01.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import "ISRevealAndMoveAnimator.h"

@interface ISRevealAndMoveAnimator()

@property (nonatomic, assign) CGPoint targetCenter;
@property (nonatomic, assign) CGFloat targetAlpha;

@end

@implementation ISRevealAndMoveAnimator

- (void)prepareToAnimate
{
    self.targetAlpha      = self.targetView.alpha;
    self.targetView.alpha = self.startingAlpha;
    
    self.targetCenter      = self.targetView.center;
    self.targetView.center = CGPointMake(self.targetCenter.x + self.deltaMove.width,
                                         self.targetCenter.y + self.deltaMove.height);
}

- (void)animateForDuration:(NSTimeInterval)duration
{
    [UIView animateWithDuration:duration
                     animations:^{
                         self.targetView.center = self.targetCenter;
                         self.targetView.alpha  = self.targetAlpha;
                     }];
}

@end
