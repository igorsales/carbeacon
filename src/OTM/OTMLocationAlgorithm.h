//
//  OTMLocationAlgorithm.h
//  CarBeacon
//
//  Created by Igor Sales on 2015-10-22.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>


@class OTMLocationMonitor;
@class OTMLocationAlgorithm;

@protocol OTMLocationAlgorithmDelegate <NSObject>

- (void)locationAlgorithm:(OTMLocationAlgorithm*)algo acquiredLocation:(CLLocation*)location;

@end

@interface OTMLocationAlgorithm : NSObject <CLLocationManagerDelegate>

@property (nonatomic, weak)   CLLocationManager*  locationManager;

@property (nonatomic, weak)   NSTimer* locationTimer;
@property (nonatomic, assign) BOOL acquiringLocation;
@property (nonatomic, strong) NSDate* acquiringLocationTimestamp;
@property (nonatomic, strong) CLLocation* lastAcquiredLocation;

@property (nonatomic, weak)   id<OTMLocationAlgorithmDelegate>   delegate;

@property (nonatomic, readonly) BOOL running;

- (void)start;
- (void)stop;

- (void)pushBeaconUUID:(NSUUID*)beaconUUID;
- (NSArray*)beaconUUIDs;

@end
