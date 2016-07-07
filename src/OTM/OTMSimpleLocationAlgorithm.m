//
//  OTMSimpleLocationAlgorithm.m
//  CarBeacon
//
//  Created by Igor Sales on 2015-10-25.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import "OTMSimpleLocationAlgorithm.h"
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

#define IS_LOG_TO_FILE 1
#define IS_LOG_LEVEL IS_LOG_LEVEL_DEBUG
#import "ISLog.h"

@interface OTMLocationAlgorithm()

- (void)resetBeaconUUIDs;

@end


@interface OTMSimpleLocationAlgorithm()

@property (nonatomic, strong) NSArray* acquiredLocations;

@property (nonatomic, assign) UIBackgroundTaskIdentifier bgndTaskId;

@end

@implementation OTMSimpleLocationAlgorithm

#pragma mark - Accessors

- (BOOL)running
{
    return self.acquiringLocation;
}

#pragma mark - Operations

- (void)start
{
    [self startAcquiringLocation];
}

- (void)stop
{
    [self stopAcquiringLocation];
    [self endBackgroundTask];
}

#pragma mark - Private

- (void)startBackgroundTask
{
    if (self.bgndTaskId == UIBackgroundTaskInvalid) {
        self.bgndTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [self stopAcquiringLocation];
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

- (void)startAcquiringLocation
{
    if (self.acquiringLocation) {
        ISLogInfo(@"Already acquiring location");
        return;
    }
    
    [self startBackgroundTask];
    
    ISLogInfo(@"Started acquiring location");
    
    self.acquiringLocation = YES;
    self.acquiredLocations = @[];
    self.acquiringLocationTimestamp = [NSDate date];
    
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter  = 0.01; // 10cm
    [self.locationManager startUpdatingLocation];
}

- (void)stopAcquiringLocation
{
    if (!self.acquiringLocation) {
        return;
    }
    
    ISLogInfo(@"Stopped acquiring location");
    
    [self.locationManager stopUpdatingLocation];
    [self resetBeaconUUIDs];
    
    self.acquiringLocation = NO;
    
    [self endBackgroundTask];
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
    
    [self.locationManager stopUpdatingLocation];
    
    [self.delegate locationAlgorithm:self acquiredLocation:locations.lastObject];
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
