//
//  OTMMapAnnotation.m
//  CarBeacon
//
//  Created by Igor Sales on 2015-10-19.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import "OTMMapAnnotation.h"

@implementation OTMMapAnnotation

#pragma mark - Setup/teardown

- (id)initWithObservation:(OTMLocationObservation *)observation
{
    if (self = [super init]) {
        _observation = observation;
    }
    
    return self;
}

#pragma mark - MKAnnotation

- (CLLocationCoordinate2D)coordinate
{
    return self.observation.location.coordinate;
}

@end
