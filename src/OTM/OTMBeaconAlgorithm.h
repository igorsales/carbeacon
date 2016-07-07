//
//  OTMBeaconAlgorithm.h
//  CarBeacon
//
//  Created by Igor Sales on 2015-11-03.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef enum {
    OTMLocationMonitoringStateOutside,
    OTMLocationMonitoringStateEntering,
    OTMLocationMonitoringStateInside,
    OTMLocationMonitoringStateLeaving
} OTMLocationMonitoringState;

typedef enum {
    OTMBeaconRangingStateOff,
    OTMBeaconRangingStateImmediateOrNear,
    OTMBeaconRangingStateFarOrUnknown,
    OTMBeaconRangingStateDone
} OTMBeaconRangingState;


@class OTMBeaconAlgorithm;
@class OTMLocationAlgorithm;

@protocol OTMBeaconAlgorithmDelegate <NSObject>

- (void)beaconAlgorithm:(OTMBeaconAlgorithm*)algorithm stateChangeOnBeaconWithUUID:(NSUUID*)beaconUUID;

@end


@interface OTMBeaconAlgorithm : NSObject <CLLocationManagerDelegate>

@property (nonatomic, strong) CLBeaconRegion*     region;
@property (nonatomic, weak)   CLLocationManager*  locationManager;

@property (nonatomic, assign) OTMLocationMonitoringState monitoringState;
@property (nonatomic, weak)   NSTimer* monitoringStateTimer;

@property (nonatomic, assign) OTMBeaconRangingState rangingState;
@property (nonatomic, weak)   NSTimer* rangingStateTimer;

@property (nonatomic, weak)   OTMLocationAlgorithm* locationAlgorithm;

@property (nonatomic, readonly) BOOL running;

@property (nonatomic, weak)   id<OTMBeaconAlgorithmDelegate> delegate;

- (void)start;
- (void)stop;

@end
