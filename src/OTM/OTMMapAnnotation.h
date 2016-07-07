//
//  OTMMapAnnotation.h
//  CarBeacon
//
//  Created by Igor Sales on 2015-10-19.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "OTMLocationObservation.h"

@interface OTMMapAnnotation : NSObject<MKAnnotation>

@property (nonatomic, readonly) OTMLocationObservation* observation;

@property (nonatomic, copy)   NSString* title;
@property (nonatomic, copy)   NSString* subtitle;

- (id)initWithObservation:(OTMLocationObservation*)observation;

@end
