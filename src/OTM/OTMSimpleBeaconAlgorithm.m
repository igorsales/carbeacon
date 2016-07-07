//
//  OTMSimpleBeaconAlgorithm.m
//  CarBeacon
//
//  Created by Igor Sales on 2015-11-03.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import "OTMSimpleBeaconAlgorithm.h"
#import "OTMLocationAlgorithm.h"

#import <UIKit/UIKit.h>

#define IS_LOG_TO_FILE 1
#define IS_LOG_LEVEL IS_LOG_LEVEL_DEBUG
#import "ISLog.h"


@interface OTMSimpleBeaconAlgorithm()

@property (nonatomic, assign) BOOL isLookingForBeacon;
@property (nonatomic, assign) BOOL isRangingBeacon;
@property (nonatomic, assign) UIBackgroundTaskIdentifier bgndTaskId;

@property (nonatomic, weak)   NSTimer* rangingTimer;

@end

@implementation OTMSimpleBeaconAlgorithm

#pragma mark - Setup/teardown

- (id)init
{
    if ((self = [super init])) {
        [self setup];
    }

    return self;
}

- (void)setup
{
    self.rangingTimeout = 4.0; // seconds
}

#pragma mark - Accessors

- (BOOL)running
{
    return self.isLookingForBeacon;
}

#pragma mark - Operations

- (void)start
{
    [self startLookingForBeacon];
}

- (void)stop
{
    [self stopLookingForBeacon];
    [self stopRangingBeacon];
}

#pragma mark - Private

- (void)startBackgroundTask
{
    if (self.bgndTaskId == UIBackgroundTaskInvalid) {
        self.bgndTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [self stopRangingBeacon];
            [self endBackgroundTask];
        }];
    }
}

- (void)endBackgroundTask
{
    if (self.bgndTaskId != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:self.bgndTaskId];
        self.bgndTaskId = UIBackgroundTaskInvalid;
    }
}

- (void)determineStateForBeacon
{
    [self.locationManager requestStateForRegion:self.region];
}

- (void)startLookingForBeacon
{
    if (self.isLookingForBeacon) {
        return;
    }

    self.isLookingForBeacon = YES;
    [self.locationManager requestStateForRegion:self.region];
    [self.locationManager startMonitoringForRegion:self.region];
    ISLogInfo(@"Started looking for beacon %@", self.region.proximityUUID);
}

- (void)stopLookingForBeacon
{
    if (!self.isLookingForBeacon) {
        return;
    }
    
    [self.locationManager stopMonitoringForRegion:self.region];
    self.isLookingForBeacon = NO;
    ISLog(@"Stopped looking for beacon %@", self.region.proximityUUID);
}

- (void)startRangingBeacon
{
    if (self.isRangingBeacon) {
        return;
    }
    
    ISLogInfo(@"Ranging started");
    
    [self startRangingTimer];
    
    self.isRangingBeacon = YES;
    [self.locationManager startRangingBeaconsInRegion:self.region];
}

- (void)stopRangingBeacon
{
    if (!self.isRangingBeacon) {
        return;
    }
    
    ISLogInfo(@"Ranging stopped");

    [self stopRangingTimer];

    [self.locationManager stopRangingBeaconsInRegion:self.region];
    self.isRangingBeacon = NO;
}

- (void)startRangingTimer
{
    if (self.rangingTimer) {
        return;
    }

    self.rangingTimer = [NSTimer timerWithTimeInterval:self.rangingTimeout
                                                target:self
                                              selector:@selector(rangingTimerFired:)
                                              userInfo:nil
                                               repeats:NO];
}

- (void)stopRangingTimer
{
    if (!self.rangingTimeout) {
        return;
    }

    [self.rangingTimer invalidate];
    self.rangingTimer = nil;
}

- (void)rangingTimerFired:(NSTimer*)timer
{
    ISLogInfo(@"Ranging timed out", nil);
    [self handoffToLocationAcquisition];
}

- (void)handoffToLocationAcquisition
{
    [self stopRangingBeacon];
    [self.locationAlgorithm pushBeaconUUID:self.region.proximityUUID];
    [self.locationAlgorithm start];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    ISLogInfo(@"monitoring did fail for region: %@ %@", region, error);
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    if (!self.isLookingForBeacon) {
        ISLogInfo(@"disregarding state %@ for beacon %@", @(state), region);
        return;
    }

    ISLogInfo(@"did determine state: %@ forRegion: %@", @((long)state), region);
    
    // In case we just started, we gotta find out if already inside the region
    if (state == CLRegionStateInside) {
        [self startBackgroundTask];
        [self startRangingBeacon];
    } else if (state == CLRegionStateOutside) {
        [self stopRangingBeacon];
    }
    
    [self.delegate beaconAlgorithm:self stateChangeOnBeaconWithUUID:self.region.proximityUUID];
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    ISLogInfo(@"did enter region %@", region);
    
    [self startBackgroundTask];
    [self startRangingBeacon];
    
    [self.delegate beaconAlgorithm:self stateChangeOnBeaconWithUUID:self.region.proximityUUID];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    ISLogInfo(@"did exit region %@", region);
    
    [self stopRangingBeacon];
    [self endBackgroundTask];
    
    [self.delegate beaconAlgorithm:self stateChangeOnBeaconWithUUID:self.region.proximityUUID];
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    ISLogInfo(@"Beacons %@ in region %@", beacons, region);
    
    for (CLBeacon* beacon in beacons) {
        // go through each and everyone. Stop at first found
        if (beacon.proximity == CLProximityImmediate ||
            beacon.proximity == CLProximityNear ||
            beacon.accuracy <= 5.0) {
            [self handoffToLocationAcquisition];
            break;
        }
        
        [self.delegate beaconAlgorithm:self stateChangeOnBeaconWithUUID:self.region.proximityUUID];
    }
}

@end
