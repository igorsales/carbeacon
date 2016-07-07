//
//  OTMRSSICalibrationAlgorithm.m
//  CarBeacon
//
//  Created by Igor Sales on 2015-11-11.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import "OTMRSSICalibrationAlgorithm.h"

#import "ISLog.h"

@interface OTMRSSICalibrationAlgorithm()

@property (nonatomic, assign) CGFloat         progress;
@property (nonatomic, assign) NSInteger       measuredAccum;
@property (nonatomic, assign) NSInteger       sampleCount;
@property (nonatomic, weak)   NSTimer*        measureTimer;

@end


@implementation OTMRSSICalibrationAlgorithm

#pragma mark - Setup/teardown

- (id)init
{
    if (self = [super init]) {
        self.duration = 25.0;
        self.durationStep = 1.0;
    }

    return self;
}

#pragma mark - Operations

- (void)start
{
    [self startBeaconCalibration];
}

- (void)stop
{
    [self abortBeaconCalibration];
}

#pragma mark - Private

- (void)startBeaconCalibration
{
    self.measuredAccum = self.sampleCount = 0;
    
    [self measureSample];
    
    [self.delegate calibrationAlgorithmDidStart:self];
    
    self.progress = 0;
    [self.delegate calibrationAlgorithm:self didProgressTo:self.progress];
    
    self.measureTimer = [NSTimer scheduledTimerWithTimeInterval:self.durationStep
                                                         target:self
                                                       selector:@selector(measureTimerFired:)
                                                       userInfo:@{ @"start": [NSDate date] }
                                                        repeats:YES];
}

- (void)measureSample
{
    if (self.device.state == BLKDeviceStateConnected) {
        ISLogInfo(@"Added sample RSSI: %@", @(self.device.signalStrength));
        self.measuredAccum += self.device.signalStrength;
        self.sampleCount++;
    }
}

- (void)measureTimerFired:(NSTimer*)timer
{
    [self measureSample];
    
    self.progress = self.progress + self.durationStep/self.duration;
    [self.delegate calibrationAlgorithm:self didProgressTo:self.progress];
    
    if (-[timer.userInfo[@"start"] timeIntervalSinceNow] >= self.duration) {
        [self endBeaconCalibration];
    }
}

- (void)abortBeaconCalibration
{
    [self.measureTimer invalidate];
    self.measureTimer = nil;
    
    ISLogInfo(@"Aborted beacon calibration");
    
    [self.delegate calibrationAlgorithmDidFail:self];
}

- (void)endBeaconCalibration
{
    [self.measureTimer invalidate];
    self.measureTimer = nil;
    
    if (self.sampleCount > 0) {
        self.measuredRSSI = (int8_t)round((double)self.measuredAccum / self.sampleCount);
        ISLogInfo(@"Calibrated RSSI: %d (%ld/%ld)", self.measuredRSSI, self.measuredAccum, self.sampleCount);
        
        [self.delegate calibrationAlgorithm:self didFinishWithMeasuredRSSI:self.measuredRSSI];
    } else {
        ISLogError(@"No samples, couldn't calibrate power");
        self.measuredRSSI = 0;
        
        [self.delegate calibrationAlgorithmDidFail:self];
    }
}


@end
