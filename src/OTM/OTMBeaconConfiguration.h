//
//  OTMBeaconConfiguration.h
//  OCTM
//
//  Created by Igor Sales on 2015-09-22.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTMBeaconConfiguration : NSObject

@property (nonatomic, assign) double thresholdON;
@property (nonatomic, assign) double thresholdFULL;
@property (nonatomic, assign) double thresholdCRANK;

@property (nonatomic, assign) NSTimeInterval stateChangeTimeout;
@property (nonatomic, assign) NSTimeInterval onOffTimeout;
@property (nonatomic, assign) NSTimeInterval ADCTimeout;

@property (nonatomic, assign) double  currentReading;

@end
