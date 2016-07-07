//
//  ISBackgroundColourAnimator.m
//  BTConnTest
//
//  Created by Igor Sales on 2015-09-01.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import "ISBackgroundColourAnimator.h"

@interface ISBackgroundColourAnimator()

@property (nonatomic, strong) UIColor* targetColour;

@end

@implementation ISBackgroundColourAnimator

- (void)prepareToAnimate
{
    self.targetColour = self.targetView.backgroundColor;
    self.targetView.backgroundColor = self.startingColour;
}

- (void)animateForDuration:(NSTimeInterval)duration
{
    [UIView animateWithDuration:self.duration
                     animations:^{
                         self.targetView.backgroundColor = self.targetColour;
                     }];
}

@end
