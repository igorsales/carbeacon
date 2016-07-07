//
//  OTMLocationAlgorithm.m
//  CarBeacon
//
//  Created by Igor Sales on 2015-10-22.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import "OTMLocationAlgorithm.h"
#import <UIKit/UIKit.h>

#define IS_LOG_TO_FILE 1
#define IS_LOG_LEVEL IS_LOG_LEVEL_DEBUG
#import "ISLog.h"


@interface OTMLocationAlgorithm()

@property (nonatomic, strong) NSArray*        acquiredLocations;
@property (nonatomic, strong) NSMutableArray* backgroundTasks;

@property (nonatomic, strong) NSMutableSet*   beaconUUIDSet;

@end

@implementation OTMLocationAlgorithm

#pragma mark - Setup/teardown

- (id)init
{
    if (self = [super init]) {
        _backgroundTasks = [NSMutableArray new];
        _beaconUUIDSet   = [NSMutableSet new];
    }

    return self;
}

#pragma mark - Accessors

- (BOOL)running
{
    return self.acquiringLocation;
}

- (NSArray*)beaconUUIDs
{
    return [_beaconUUIDSet allObjects];
}

#pragma mark - Private

- (void)startBackgroundTask
{
    UIBackgroundTaskIdentifier taskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [self stopAcquiringLocation];
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

#pragma mark - Operations

- (void)start
{
    [self startAcquiringLocation];
}

- (void)stop
{
    [self stopAcquiringLocation];
}

- (void)pushBeaconUUID:(NSUUID *)beaconUUID
{
    [_beaconUUIDSet addObject:beaconUUID];
}

#pragma mark - Private

- (void)resetBeaconUUIDs
{
    [_beaconUUIDSet removeAllObjects];
}

- (void)startAcquiringLocation
{
    if (self.acquiringLocation) {
        ISLogInfo(@"Already acquiring location");
        return;
    }
    
    ISLogInfo(@"Started acquiring location");
    
    [self resetBeaconUUIDs];

    self.acquiringLocation = YES;
    self.acquiredLocations = @[];
    self.acquiringLocationTimestamp = [NSDate date];
    
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter  = 0.01; // 10cm
    [self.locationManager startUpdatingLocation];
    
    [self startLocationTimer];
}

- (void)stopAcquiringLocation
{
    if (!self.acquiringLocation) {
        return;
    }
    
    ISLogInfo(@"Stopped acquiring location");
    
    [self stopLocationTimer];
    [self.locationManager stopUpdatingLocation];
    
    self.acquiringLocation = NO;
}

- (void)startLocationTimer
{
    [self stopLocationTimer];
    self.locationTimer = [NSTimer scheduledTimerWithTimeInterval:7.5
                                                          target:self
                                                        selector:@selector(locationTimerFired:)
                                                        userInfo:nil
                                                         repeats:NO];
}

- (void)stopLocationTimer
{
    [self.locationTimer invalidate];
}

- (void)locationTimerFired:(NSTimer*)timer
{
    [self stopAcquiringLocation];
    [self processAcquiredLocations];
}

- (void)processAcquiredLocations
{
    ISLogInfo(@"Acquired locations %@", self.acquiredLocations);
    if (self.acquiredLocations.count) {
        [self.delegate locationAlgorithm:self acquiredLocation:self.acquiredLocations.lastObject];
    }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager
{
    ISLogInfo(@"paused location updates");
}

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager
{
    ISLogInfo(@"Resumed location updates");
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    self.acquiredLocations    = [self.acquiredLocations arrayByAddingObjectsFromArray:locations];
    self.lastAcquiredLocation = locations.lastObject;
    
    [self processAcquiredLocations];
    [self stopAcquiringLocation];
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    // ignore
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    // ignore
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    // ignore
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    // ignore
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    // ignore
}

@end
