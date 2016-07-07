//
//  OTMProximityView.m
//  BTConnTest
//
//  Created by Igor Sales on 2015-10-17.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import "OTMProximityView.h"
#import <QuartzCore/QuartzCore.h>

@interface OTMProximityView()

@property (nonatomic, weak) NSTimer* blinkTimer;

@end

@implementation OTMProximityView

- (void)setTintColor:(UIColor *)tintColor
{
    [super setTintColor:tintColor];

    [self updateView];
}

- (void)setProximity:(OTMProximity)proximity
{
    if (proximity != _proximity) {
        _proximity = proximity;
        [self updateView];
    }
}

- (void)awakeFromNib
{
    [self updateView];
}

- (void)updateView
{
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius  = MIN(self.bounds.size.width, self.bounds.size.height) / 2;
    self.layer.borderWidth   = 2.2;
    self.layer.borderColor   = self.tintColor.CGColor;

    switch (self.proximity) {
        case OTMProximityOutside:
            [self stopBlinking];
            self.layer.borderColor     = [self.tintColor colorWithAlphaComponent:0.11].CGColor;
            self.layer.backgroundColor = [self.tintColor colorWithAlphaComponent:0.055].CGColor;
            break;

        default:
        case OTMProximityUnknown:
            [self startBlinking];
            self.layer.backgroundColor = [self.tintColor colorWithAlphaComponent:0.11].CGColor;
            break;

        case OTMProximityFar:
            [self stopBlinking];
            self.layer.backgroundColor = [self.tintColor colorWithAlphaComponent:0.33].CGColor;
            break;
            
        case OTMProximityNear:
            [self stopBlinking];
            self.layer.backgroundColor = [self.tintColor colorWithAlphaComponent:0.55].CGColor;
            break;

        case OTMProximityImmediate:
            [self stopBlinking];
            self.layer.backgroundColor = [self.tintColor colorWithAlphaComponent:0.87].CGColor;
            break;
    }
}

- (void)startBlinking
{
    [self stopBlinking];
    self.blinkTimer = [NSTimer scheduledTimerWithTimeInterval:1.125
                                                       target:self
                                                     selector:@selector(blinkTimerFired:)
                                                     userInfo:nil
                                                      repeats:YES];
}

- (void)stopBlinking
{
    [self.blinkTimer invalidate];
    self.alpha = 1.0;
}

- (void)blinkTimerFired:(NSTimer*)timer
{
    //self.hidden = !self.hidden;
    if (self.alpha > 0.5) {
        self.alpha = 0.37;
    } else {
        self.alpha = 1.0;
    }
}

@end
