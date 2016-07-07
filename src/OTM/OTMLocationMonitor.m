//
//  OTMLocationMonitor.m
//  BTConnTest
//
//  Created by Igor Sales on 2015-08-27.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import "OTMLocationMonitor.h"
#import "OTMProximityView.h"
#import "OTMBeaconAlgorithm.h"
#import "OTMSimpleBeaconAlgorithm.h"
#import "OTMLocationAlgorithm.h"
#import "OTMSimpleLocationAlgorithm.h"

#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>


#define IS_LOG_TO_FILE 1
#define IS_LOG_LEVEL IS_LOG_LEVEL_DEBUG
#import "ISLog.h"

@interface OTMLocationMonitor() <CLLocationManagerDelegate,
                                OTMLocationAlgorithmDelegate>

@property (nonatomic, strong) CLLocationManager* locationManager;

@property (nonatomic, strong) NSArray*              beaconAlgorithms;
@property (nonatomic, strong) OTMLocationAlgorithm* locationAlgorithm;

@end

@implementation OTMLocationMonitor

#pragma mark - Setup/teardown

- (id)init
{
    if (self = [super init]) {
        _locationManager = [CLLocationManager new];
        _locationManager.delegate = self;
        
        [self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
        [self.locationManager setDistanceFilter:0.01];
        
        if ([self.locationManager respondsToSelector:@selector(setAllowsBackgroundLocationUpdates:)]) {
            self.locationManager.allowsBackgroundLocationUpdates = YES;
        }
    }

    return self;
}

#pragma mark - Accessors

- (BOOL)needsAuthorization
{
    return [CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedAlways;
}

#pragma mark - Actions

- (IBAction)requestAuthorization:(id)sender
{
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [self.locationManager requestAlwaysAuthorization];
    }
}

- (IBAction)acquireLocation:(id)sender
{
    [self.locationAlgorithm start];
}

- (IBAction)startBeaconTracking:(id)sender
{
    if (!self.locationAlgorithm) {
        self.locationAlgorithm = [OTMSimpleLocationAlgorithm new];
        self.locationAlgorithm.locationManager = self.locationManager;
        self.locationAlgorithm.delegate = self;
    }
    
    [self.beaconAlgorithms enumerateObjectsUsingBlock:^(OTMBeaconAlgorithm* algo, NSUInteger idx, BOOL* stop) {
        [algo stop];
    }];
    
    // also ensure no other beacon trackings are around
    [self.locationManager.monitoredRegions enumerateObjectsUsingBlock:^(CLBeaconRegion* r, BOOL* stop) {
        if ([r isKindOfClass:[CLBeaconRegion class]]) {
            [self.locationManager stopMonitoringForRegion:r];
        }
    }];

    NSMutableArray* algorithms = [NSMutableArray new];

    [self.beaconUUIDStrings enumerateObjectsUsingBlock:^(NSString* beaconUUIDString, NSUInteger idx, BOOL* stop) {
        NSUUID*         beaconUUID = [[NSUUID alloc] initWithUUIDString:beaconUUIDString];
        
        NSString*       beaconId   = [NSString stringWithFormat:@"org.ble-kit.CarBeacon.%d", (int)idx+1];
        
        CLBeaconRegion* region     = [[CLBeaconRegion alloc] initWithProximityUUID:beaconUUID
                                                                        identifier:beaconId];
        region.notifyOnEntry = YES;
        region.notifyOnExit = YES;
        region.notifyEntryStateOnDisplay = YES;
        
        OTMBeaconAlgorithm* algorithm = [OTMSimpleBeaconAlgorithm new];
        algorithm.region              = region;
        algorithm.locationManager     = self.locationManager;
        algorithm.locationAlgorithm   = self.locationAlgorithm;
        [algorithms addObject:algorithm];
        
        [algorithm start];
    }];
    
    self.beaconAlgorithms = algorithms;
}

- (IBAction)stopBeaconTracking:(id)sender
{
    [self.beaconAlgorithms makeObjectsPerformSelector:@selector(stop)];
}

#pragma mark - Private

- (OTMProximityView*)proximityViewForRegion:(CLRegion*)region
{
    if (![region isKindOfClass:[CLBeaconRegion class]]) {
        return nil;
    }
    
    CLBeaconRegion* beaconRegion = (CLBeaconRegion*)region;
    
    return [self.proximityViewSource proximityViewForBeaconUUID:beaconRegion.proximityUUID.UUIDString];
}

#pragma mark - Operations

- (void)encircleMarkers
{
    [self.mapView showAnnotations:self.mapView.annotations animated:YES];
}

#pragma mark - OTMLocationAlgorithmDelegate

- (void)locationAlgorithm:(OTMLocationAlgorithm *)algorithm acquiredLocation:(CLLocation *)location
{
    if ([algorithm beaconUUIDs].count) {
        [[algorithm beaconUUIDs] enumerateObjectsUsingBlock:^(NSUUID* beaconUUID, NSUInteger idx, BOOL* stop) {
            [self.delegate locationMonitor:self
                        didAcquireLocation:location
                            withBeaconUUID:beaconUUID];
        }];
    } else {
        [self.delegate locationMonitor:self
                    didAcquireLocation:location
                        withBeaconUUID:nil];
    }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    [self.locationAlgorithm locationManager:manager
               didChangeAuthorizationStatus:status];

    [self.beaconAlgorithms enumerateObjectsUsingBlock:^(OTMLocationAlgorithm* algorithm, NSUInteger idx, BOOL* stop) {
        [algorithm locationManager:manager didChangeAuthorizationStatus:status];
    }];
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager
{
    [self.locationAlgorithm locationManagerDidPauseLocationUpdates:manager];

    [self.beaconAlgorithms makeObjectsPerformSelector:@selector(locationManagerDidPauseLocationUpdates:)
                                     withObject:manager];
}

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager
{
    [self.locationAlgorithm locationManagerDidResumeLocationUpdates:manager];

    [self.beaconAlgorithms makeObjectsPerformSelector:@selector(locationManagerDidResumeLocationUpdates:)
                                     withObject:manager];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    [self.locationAlgorithm locationManager:manager
                         didUpdateLocations:locations];
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    [self.beaconAlgorithms enumerateObjectsUsingBlock:^(OTMBeaconAlgorithm* algorithm, NSUInteger idx, BOOL* stop) {
        if ([algorithm.region isEqual:region]) {
            [algorithm locationManager:manager monitoringDidFailForRegion:region withError:error];
        }
    }];
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    [self.beaconAlgorithms enumerateObjectsUsingBlock:^(OTMBeaconAlgorithm* algorithm, NSUInteger idx, BOOL* stop) {
        if ([algorithm.region isEqual:region]) {
            [algorithm locationManager:manager didDetermineState:state forRegion:region];
        }
        
        OTMProximityView* proximityView = [self proximityViewForRegion:region];
        if (!proximityView) {
            return;
        }
        
        switch (state) {
            case CLRegionStateUnknown: proximityView.proximity = OTMProximityUnknown; break;
            case CLRegionStateInside:  proximityView.proximity = OTMProximityUnknown; break;
            case CLRegionStateOutside: proximityView.proximity = OTMProximityOutside; break;
        }
    }];

}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    [self.beaconAlgorithms enumerateObjectsUsingBlock:^(OTMBeaconAlgorithm* algorithm, NSUInteger idx, BOOL* stop) {
        if ([algorithm.region isEqual:region]) {
            [algorithm locationManager:manager didEnterRegion:region];
        }
        
        OTMProximityView* proximityView = [self proximityViewForRegion:region];
        if (!proximityView) {
            return;
        }
        
        proximityView.proximity = OTMProximityUnknown;
    }];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    [self.beaconAlgorithms enumerateObjectsUsingBlock:^(OTMBeaconAlgorithm* algorithm, NSUInteger idx, BOOL* stop) {
        if ([algorithm.region isEqual:region]) {
            [algorithm locationManager:manager didExitRegion:region];
        }
        
        OTMProximityView* proximityView = [self proximityViewForRegion:region];
        if (!proximityView) {
            return;
        }
        
        proximityView.proximity = OTMProximityOutside;
    }];
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    [self.beaconAlgorithms enumerateObjectsUsingBlock:^(OTMBeaconAlgorithm* algorithm, NSUInteger idx, BOOL* stop) {
        if ([algorithm.region isEqual:region]) {
            [algorithm locationManager:manager didRangeBeacons:beacons inRegion:region];
        }
        
        if (beacons.count) {
            OTMProximityView* proximityView = [self proximityViewForRegion:region];
            if (!proximityView) {
                return;
            }
            
            // TODO: Here are counting on the fact that there will be a single beacon ever with that UUID
            CLBeacon* beacon = beacons.firstObject;
            
            proximityView.proximity = (OTMProximity)beacon.proximity;
        }
    }];
}

@end
