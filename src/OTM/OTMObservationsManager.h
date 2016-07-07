//
//  OTMObservationsManager.h
//  CarBeacon
//
//  Created by Igor Sales on 2015-10-18.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTMLocationDatabase.h"

@interface OTMObservationsManager : NSObject<OTMObservationDataSource>

- (id)initWithObservations:(NSArray*)observations;

@end
