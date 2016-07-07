//
//  OTMLocationDatabase.m
//  BTConnTest
//
//  Created by Igor Sales on 2015-10-17.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import "OTMLocationDatabase.h"
#import "OTMObservationsManager.h"
#import "OTMLocationObservation.h"
#import "ISLog.h"

@interface OTMLocationDatabase()

@property (nonatomic, strong) NSMutableArray* observations;

@end

@implementation OTMLocationDatabase

#pragma mark - Setup/teardown

- (id)init
{
    if (self = [super init]) {
        _observations = [NSMutableArray new];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        _observations = [aDecoder decodeObjectForKey:@"observations"];
        if (!_observations) {
            _observations = [NSMutableArray new];
        }
        
        NSAssert([_observations isKindOfClass:[NSMutableArray class]], @"Immutable observations");

        [_observations sortUsingComparator:^NSComparisonResult(OTMLocationObservation* o1,
                                                               OTMLocationObservation* o2) {
            return -[o1.location.timestamp compare:o2.location.timestamp];
        }];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.observations forKey:@"observations"];
}

#pragma mark - Private

- (NSArray*)observationsFromPredicate:(NSPredicate*)predicate
{
    return [self.observations filteredArrayUsingPredicate:predicate];
}

#pragma mark - Operations

- (void)addObservation:(OTMLocationObservation*)observation
{
    if (observation.fromUserId) {
        OTMLocationObservation* latest = nil;
        if (observation.beaconUUIDString) {
            latest = [self latestObservationFromPeer:observation.fromUserId forBeacon:observation.beaconUUIDString];
        } else {
            latest = [self latestObservationFromPeer:observation.fromUserId];
        }
        
        if (latest &&
            [latest.location.timestamp compare:observation.location.timestamp] != NSOrderedAscending) {
            ISLogInfo(@"Not adding location for older timestamp: %@", latest.location);
            return;
        }
    }

    [self.observations insertObject:observation atIndex:0];
}

- (void)removeObservationsFor:(NSString*)peerID
{
    NSPredicate* pred = [NSPredicate predicateWithFormat:@"fromUserId != %@", peerID];

    [self.observations filterUsingPredicate:pred];
}

- (id)dataSourceForOwnObservations
{
    NSArray* observations = [self observationsFromPredicate:
                             [NSPredicate predicateWithFormat:@"fromUserId = nil"]];
    
    return [[OTMObservationsManager alloc] initWithObservations:observations];
}

- (id)dataSourceForObservationsFromPeer:(NSString*)userId
{
    NSArray* observations = [self observationsFromPredicate:
                             [NSPredicate predicateWithFormat:@"fromUserId = %@", userId]];
    
    return [[OTMObservationsManager alloc] initWithObservations:observations];
}

- (id)dataSourceForObservationsFromBeaconUUIDString:(NSString*)beaconUUIDString
{
    NSArray* observations = [self observationsFromPredicate:
                             [NSPredicate predicateWithFormat:@"beaconUUIDString = %@", beaconUUIDString]];
    
    return [[OTMObservationsManager alloc] initWithObservations:observations];
}

- (id)dataSourceForObservationsFromBeaconUUIDStrings:(NSArray*)beaconUUIDStrings;
{
    NSArray* observations = [self observationsFromPredicate:
                             [NSPredicate predicateWithFormat:@"%@ CONTAINS beaconUUIDString", beaconUUIDStrings]];
    
    return [[OTMObservationsManager alloc] initWithObservations:observations];
}

- (OTMLocationObservation*)latestObservationForBeaconUUIDString:(NSString *)beaconUUIDString
{
    OTMObservationsManager* mgr = [self dataSourceForObservationsFromBeaconUUIDString:beaconUUIDString];
    
    return mgr.allObservations.firstObject;
}

- (OTMLocationObservation*)latestObservationFromAnyPeerForBeacon:(NSString *)beaconUUIDString
{
    NSArray* observations = [self observationsFromPredicate:
                             [NSPredicate predicateWithFormat:@"beaconUUIDString = %@ AND fromUserId != nil", beaconUUIDString]];
    
    return observations.firstObject;
}

- (OTMLocationObservation*)latestObservationFromPeer:(NSString*)peerID
{
    NSArray* observations = [self observationsFromPredicate:
                             [NSPredicate predicateWithFormat:@"fromUserId = %@",
                              peerID]];
    
    return observations.firstObject;
}

- (OTMLocationObservation*)latestObservationFromPeer:(NSString*)peerID forBeacon:(NSString *)beaconUUIDString
{
    NSArray* observations = [self observationsFromPredicate:
                             [NSPredicate predicateWithFormat:@"beaconUUIDString = %@ AND fromUserId = %@", beaconUUIDString,
                              peerID]];
    
    return observations.firstObject;
}

@end
