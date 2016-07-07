//
//  OTMObservationsManager.m
//  CarBeacon
//
//  Created by Igor Sales on 2015-10-18.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import "OTMObservationsManager.h"
#import "NSDate+Helpers.h"
#import "OTMLocationObservation.h"

@interface OTMObservationsManager()

@property (nonatomic, strong) NSArray* observations;
@property (nonatomic, strong) NSArray* observationDays;
@property (nonatomic, strong) NSDictionary* observationDayToObservationsMap;

@end

@implementation OTMObservationsManager

- (id)initWithObservations:(NSArray *)observations
{
    if (self = [super init]) {
        _observations = observations;
    }

    return self;
}

#pragma mark - OTMObservationsDataSource

- (OTMLocationObservation*)lastObservation
{
    return self.observations.lastObject;
}

- (NSArray*)allObservations
{
    return self.observations;
}

- (NSArray*)observationDays
{
    if (!_observationDays) {
        NSMutableSet* observationDays = [NSMutableSet new];
        NSMutableDictionary* map = [NSMutableDictionary new];

        [self.observations enumerateObjectsUsingBlock:^(OTMLocationObservation* obs, NSUInteger idx, BOOL* stop) {
            NSDate* day = [obs.location.timestamp dateWithoutTime];
            [observationDays addObject:day];
            
            NSMutableArray* observations = map[day.description];
            if (!observations) {
                observations = [NSMutableArray new];
                map[day.description] = observations;
            }
            
            [observations addObject:obs];
        }];
        
        _observationDays = [[observationDays allObjects]
                            sortedArrayUsingComparator:^NSComparisonResult(NSDate* d1, NSDate* d2) {
                                return -[d1 compare:d2];
                            }];
        _observationDayToObservationsMap = map;
    }
    
    return _observationDays;
}

- (NSArray*)observationsForDay:(NSDate*)day
{
    if (!_observationDayToObservationsMap) {
        [self observationDays];
    }
    
    return _observationDayToObservationsMap[day.description];
}

@end
