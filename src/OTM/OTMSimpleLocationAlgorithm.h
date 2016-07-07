//
//  OTMSimpleLocationAlgorithm.h
//  CarBeacon
//
//  Created by Igor Sales on 2015-10-25.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTMLocationAlgorithm.h"

@interface OTMSimpleLocationAlgorithm : OTMLocationAlgorithm

- (void)start;
- (void)stop;

- (void)startAcquiringLocation;

@end
