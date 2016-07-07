//
//  ISAnimator.m
//  BTConnTest
//
//  Created by Igor Sales on 2015-09-01.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import "ISAnimator.h"

@interface ISAnimator()

@property (nonatomic, weak) NSTimer* startTimer;
@property (nonatomic, weak) NSTimer* nextAnimatorsTimer;

@end

@implementation ISAnimator

#pragma mark - Actions

- (IBAction)prepareToAnimate:(id)sender
{
    NSMutableArray* queue = [NSMutableArray arrayWithObject:self];

    while (queue.count) {
        ISAnimator* animator = [queue firstObject];
        
        [animator prepareToAnimate];
        
        [queue removeObjectAtIndex:0];
        [queue addObjectsFromArray:animator.nextAnimators];
    }
}

- (IBAction)startAnimating:(id)sender
{
    self.startTimer = [NSTimer scheduledTimerWithTimeInterval:self.startDelay
                                                       target:self
                                                     selector:@selector(startTimerFired:)
                                                     userInfo:nil
                                                      repeats:NO];

    self.nextAnimatorsTimer = [NSTimer scheduledTimerWithTimeInterval:self.timeToAnimateNextAnimators
                                                               target:self
                                                             selector:@selector(triggerNextAnimatorsTimerFired:)
                                                             userInfo:nil
                                                              repeats:NO];
}

#pragma mark - Operations

- (void)prepareToAnimate
{
    
}

- (void)animateForDuration:(NSTimeInterval)duration
{
    // override with the animation
}

#pragma mark - Private

- (void)startTimerFired:(NSTimer*)timer
{
    [self animateForDuration:self.duration];
}

- (void)triggerNextAnimatorsTimerFired:(NSTimer*)timer
{
    for (ISAnimator* nextAnimator in self.nextAnimators) {
        [nextAnimator startAnimating:self];
    }
}

@end
