//
//  OTMBeaconAlgorithm.m
//  CarBeacon
//
//  Created by Igor Sales on 2015-11-03.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import "OTMBeaconAlgorithm.h"
#import "OTMLocationAlgorithm.h"
#import <UIKit/UIKit.h>

#define IS_LOG_TO_FILE 1
#define IS_LOG_LEVEL IS_LOG_LEVEL_DEBUG
#import "ISLog.h"


@interface OTMBeaconAlgorithm()

@property (nonatomic, strong) NSMutableArray* backgroundTasks;

@end

@implementation OTMBeaconAlgorithm

#pragma mark - Setup/teardown

- (id)init
{
    if (self = [super init]) {
        _backgroundTasks = [NSMutableArray new];
    }
    
    return self;
}

#pragma mark - Accessors

- (BOOL)running
{
    return self.monitoringState != OTMLocationMonitoringStateOutside ||
           self.rangingState != OTMBeaconRangingStateOff;
}

#pragma mark - Operations

- (void)start
{
    [self startStateMachine];
}

- (void)stop
{
    [self stopStateMachine];
}

#pragma mark - Private

- (void)startBackgroundTask
{
    UIBackgroundTaskIdentifier taskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [self stopRanging];
        [self endBackgroundTask];
    }];
    
    if (taskId != UIBackgroundTaskInvalid) {
        [self.backgroundTasks addObject:@(taskId)];
    } else {
        ISLogInfo(@"Cannot get a bgnd task Id");
    }
}

- (void)endBackgroundTask
{
    if (!self.backgroundTasks.count) {
        return;
    }
    
    UIBackgroundTaskIdentifier taskId = [self.backgroundTasks[0] unsignedIntegerValue];
    
    [[UIApplication sharedApplication] endBackgroundTask:taskId];
    
    [self.backgroundTasks removeObjectAtIndex:0];
}

- (void)startStateMachine
{
    [self.locationManager startMonitoringForRegion:self.region];
    
    self.monitoringState = OTMLocationMonitoringStateOutside;
    self.rangingState    = OTMBeaconRangingStateOff;
    
    ISLogInfo(@"Started state machine");
}

- (void)stopStateMachine
{
    [self stopRanging];
    [self stopMonitoringTimer];
}

- (void)transitionDidEnterRegion
{
    switch (self.monitoringState) {
        case OTMLocationMonitoringStateOutside:
            [self startMonitoringTimer];
            self.monitoringState = OTMLocationMonitoringStateEntering;
            [self startRanging];
            
            // start getting location right away
            [self.locationAlgorithm pushBeaconUUID:self.region.proximityUUID];
            [self.locationAlgorithm start];
            
            [self.delegate beaconAlgorithm:self stateChangeOnBeaconWithUUID:self.region.proximityUUID];
            break;
            
        case OTMLocationMonitoringStateEntering:
            break;
            
        case OTMLocationMonitoringStateInside:
            break;
            
        case OTMLocationMonitoringStateLeaving:
            [self startMonitoringTimer];
            self.monitoringState = OTMLocationMonitoringStateEntering;
            break;
    }
}

- (void)transitionDidLeaveRegion
{
    switch (self.monitoringState) {
        case OTMLocationMonitoringStateOutside:
            break;
            
        case OTMLocationMonitoringStateEntering:
            [self startMonitoringTimer];
            self.monitoringState = OTMLocationMonitoringStateLeaving;
            break;
            
        case OTMLocationMonitoringStateInside:
            [self startMonitoringTimer];
            self.monitoringState = OTMLocationMonitoringStateLeaving;
            break;
            
        case OTMLocationMonitoringStateLeaving:
            break;
    }
}

- (void)transitionToNearBeacon
{
    switch (self.monitoringState) {
        case OTMLocationMonitoringStateOutside:
            break;
            
        case OTMLocationMonitoringStateEntering:
            [self stopMonitoringTimer];
            self.monitoringState = OTMLocationMonitoringStateInside;
            
            // at this point we could already be acquiring location, so just reset the timer
            [self.locationAlgorithm pushBeaconUUID:self.region.proximityUUID];
            [self.locationAlgorithm start];
            
            [self.delegate beaconAlgorithm:self stateChangeOnBeaconWithUUID:self.region.proximityUUID];
            break;
            
        case OTMLocationMonitoringStateInside:
            break;
            
        case OTMLocationMonitoringStateLeaving:
            break;
    }
}

- (void)monitoringTimeout
{
    switch (self.monitoringState) {
        case OTMLocationMonitoringStateOutside:
            break;
            
        case OTMLocationMonitoringStateEntering:
            self.monitoringState = OTMLocationMonitoringStateInside;
            [self.locationAlgorithm pushBeaconUUID:self.region.proximityUUID];
            [self.locationAlgorithm start];
            
            [self.delegate beaconAlgorithm:self stateChangeOnBeaconWithUUID:self.region.proximityUUID];
            break;
            
        case OTMLocationMonitoringStateInside:
            break;
            
        case OTMLocationMonitoringStateLeaving:
            [self stopRanging];
            self.monitoringState = OTMLocationMonitoringStateOutside;
            [self endBackgroundTask];
            break;
    }
}

- (void)startMonitoringTimer
{
    [self stopMonitoringTimer];
    self.monitoringStateTimer = [NSTimer scheduledTimerWithTimeInterval:15.0
                                                                 target:self
                                                               selector:@selector(monitoringTimerFired:)
                                                               userInfo:nil
                                                                repeats:NO];
}

- (void)stopMonitoringTimer
{
    [self.monitoringStateTimer invalidate];
}

- (void)monitoringTimerFired:(NSTimer*)timer
{
    [self monitoringTimeout];
}

- (void)startRanging
{
    if (self.rangingState != OTMBeaconRangingStateOff) {
        ISLogInfo(@"Already ranging beacon");
        return;
    }
    
    ISLogInfo(@"Ranging started");
    
    self.rangingState = OTMBeaconRangingStateFarOrUnknown;
    [self.locationManager startRangingBeaconsInRegion:self.region];
}

- (void)stopRanging
{
    if (self.rangingState == OTMBeaconRangingStateOff) {
        ISLogInfo(@"Not ranging beacon");
        return;
    }
    
    ISLogInfo(@"Ranging stopped");
    
    [self.locationManager stopRangingBeaconsInRegion:self.region];
    self.rangingState = OTMBeaconRangingStateOff;
    [self stopRangingTimer];
}

- (void)transitionToBeaconRange:(CLBeacon*)beacon
{
    if (self.rangingState == OTMBeaconRangingStateOff) {
        ISLogInfo(@"Cannot transition to beacon range since ranging is off");
        return;
    }
    
    switch (beacon.proximity) {
        case CLProximityUnknown:
        case CLProximityFar:
            [self transitionRangingToFarOrUnknown];
            break;
            
        case CLProximityImmediate:
        case CLProximityNear:
            [self transitionRangingToImmediateOrNear];
            break;
    }
}

- (void)transitionRangingToFarOrUnknown
{
    switch (self.rangingState) {
        case OTMBeaconRangingStateOff:
            self.rangingState = OTMBeaconRangingStateFarOrUnknown;
            break;
            
        case OTMBeaconRangingStateFarOrUnknown:
            break;
            
        case OTMBeaconRangingStateImmediateOrNear:
            [self stopRangingTimer];
            self.rangingState = OTMBeaconRangingStateFarOrUnknown;
            break;
            
        case OTMBeaconRangingStateDone:
            break;
    }
}

- (void)transitionRangingToImmediateOrNear
{
    switch (self.rangingState) {
        case OTMBeaconRangingStateOff:
            self.rangingState = OTMBeaconRangingStateImmediateOrNear;
            [self startRangingTimer];
            break;
            
        case OTMBeaconRangingStateFarOrUnknown:
            self.rangingState = OTMBeaconRangingStateImmediateOrNear;
            [self startRangingTimer];
            break;
            
        case OTMBeaconRangingStateImmediateOrNear:
            break;
            
        case OTMBeaconRangingStateDone:
            break;
    }
}

- (void)rangingTimeout
{
    switch (self.rangingState) {
        case OTMBeaconRangingStateOff:
            break;
            
        case OTMBeaconRangingStateFarOrUnknown:
            break;
            
        case OTMBeaconRangingStateImmediateOrNear:
            [self transitionToNearBeacon];
            [self.locationManager stopRangingBeaconsInRegion:self.region];
            self.rangingState = OTMBeaconRangingStateDone;
            break;
            
        case OTMBeaconRangingStateDone:
            break;
    }
}

- (void)startRangingTimer
{
    [self stopRangingTimer];
    self.rangingStateTimer = [NSTimer scheduledTimerWithTimeInterval:3.0
                                                              target:self
                                                            selector:@selector(rangingTimerFired:)
                                                            userInfo:nil
                                                             repeats:NO];
}

- (void)stopRangingTimer
{
    [self.rangingStateTimer invalidate];
}

- (void)rangingTimerFired:(NSTimer*)timer
{
    [self rangingTimeout];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status != kCLAuthorizationStatusAuthorizedAlways &&
        status != kCLAuthorizationStatusAuthorizedWhenInUse) {
        ISLogInfo(@"Unauthorized to get location.");
        [self stop];
    }
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager
{
    // ignore
}

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager
{
    // ignore
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    // ignore
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    ISLogInfo(@"monitoring did fail for region: %@ %@", region, error);
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    ISLogInfo(@"did determine state: %@ forRegion: %@", @((long)state), region);
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    ISLogInfo(@"did enter region %@", region);
    
    //[self acquireLocation:self];
    [self transitionDidEnterRegion];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    ISLogInfo(@"did exit region %@", region);
    [self transitionDidLeaveRegion];
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    ISLogInfo(@"Beacons %@ in region %@", beacons, region);
    
    for (CLBeacon* beacon in beacons) {
        // go through each and everyone. Stop at first found
        if (beacon.proximity == CLProximityImmediate ||
            beacon.proximity == CLProximityNear) {
            [self transitionToBeaconRange:beacon];
            break;
        }
    }
}


@end
