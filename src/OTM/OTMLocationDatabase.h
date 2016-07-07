//
//  OTMLocationDatabase.h
//  BTConnTest
//
//  Created by Igor Sales on 2015-10-17.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OTMLocationObservation;

@protocol OTMObservationDataSource <NSObject>

- (OTMLocationObservation*)lastObservation;
- (NSArray*)allObservations;
- (NSArray*)observationDays;
- (NSArray*)observationsForDay:(NSDate*)day;

@end

@interface OTMLocationDatabase : NSObject <NSCoding>

// Operations
- (void)addObservation:(OTMLocationObservation*)observation;
- (void)removeObservationsFor:(NSString*)peerID;

- (id<OTMObservationDataSource>)dataSourceForOwnObservations;
- (id<OTMObservationDataSource>)dataSourceForObservationsFromPeer:(NSString*)userId;
- (id)dataSourceForObservationsFromBeaconUUIDString:(NSString*)beaconUUIDString;
- (id)dataSourceForObservationsFromBeaconUUIDStrings:(NSArray*)beaconUUIDStrings;

- (OTMLocationObservation*)latestObservationForBeaconUUIDString:(NSString*)beaconUUIDString;
- (OTMLocationObservation*)latestObservationFromAnyPeerForBeacon:(NSString *)beaconUUIDString;
- (OTMLocationObservation*)latestObservationFromPeer:(NSString*)peerID;
- (OTMLocationObservation*)latestObservationFromPeer:(NSString*)peerID forBeacon:(NSString *)beaconUUIDString;

@end
