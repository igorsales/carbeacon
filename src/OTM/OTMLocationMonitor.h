//
//  OTMLocationMonitor.h
//  BTConnTest
//
//  Created by Igor Sales on 2015-08-27.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MKMapView;
@class CLRegion;
@class CLLocation;
@class OTMLocationMonitor;
@class OTMProximityView;

@protocol OTMLocationMonitorProximityViewSource <NSObject>

- (OTMProximityView*)proximityViewForBeaconUUID:(NSString*)UUID;

@end

@protocol OTMLocationMonitorDelegate <NSObject>

- (void)locationMonitor:(OTMLocationMonitor*)monitor
     didAcquireLocation:(CLLocation*)location
         withBeaconUUID:(NSUUID*)beaconUUID;

@end

@interface OTMLocationMonitor : NSObject

@property (nonatomic, readonly)          BOOL       needsAuthorization;
@property (nonatomic, strong)            NSArray*   beaconUUIDStrings;

@property (nonatomic, weak)     IBOutlet MKMapView*        mapView;

@property (nonatomic, weak)     IBOutlet id<OTMLocationMonitorDelegate> delegate;
@property (nonatomic, weak)     IBOutlet id<OTMLocationMonitorProximityViewSource> proximityViewSource;

// Actions
- (IBAction)requestAuthorization:(id)sender;
- (IBAction)acquireLocation:(id)sender;
- (IBAction)startBeaconTracking:(id)sender;
- (IBAction)stopBeaconTracking:(id)sender;

// operations
- (void)encircleMarkers;

@end
