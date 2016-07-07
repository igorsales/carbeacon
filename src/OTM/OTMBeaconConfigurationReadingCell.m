//
//  OTMBeaconConfigurationReadingCell.m
//  BTConnTest
//
//  Created by Igor Sales on 2015-09-22.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import "OTMBeaconConfigurationReadingCell.h"

@implementation OTMBeaconConfigurationReadingCell

- (void)setTarget:(id)target
{
    if (_target != target) {
        [self stopObserving];
        _target = target;
        [self startObserving];
        [self updateCurrentValue];
    }
}

- (void)setKeyPath:(NSString *)keyPath
{
    if (_keyPath != keyPath) {
        [self stopObserving];
        _keyPath = keyPath;
        [self startObserving];
        [self updateCurrentValue];
    }
}

- (void)stopObserving
{
    if (self.target && self.keyPath) {
        [self.target removeObserver:self forKeyPath:self.keyPath];
    }
}

- (void)startObserving
{
    if (self.target && self.keyPath) {
        [self.target addObserver:self
                      forKeyPath:self.keyPath
                         options:0
                         context:nil];
    }
}

- (void)dealloc
{
    [self stopObserving];
}

- (void)updateCurrentValue
{
    if (self.target && self.keyPath) {
        NSNumber* value = [self.target valueForKeyPath:self.keyPath];
        self.readingLabel.text = [NSString stringWithFormat:@"%.2f", [value doubleValue]];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self updateCurrentValue];
}

@end
