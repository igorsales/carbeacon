//
//  OTMBeaconConfigurationPort.h
//  OTCM
//
//  Created by Igor Sales on 2015-09-22.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import <BLEKit/BLEKit.h>

extern NSString* const kOTMBeaconPortTypeConfiguration;

@interface OTMBeaconConfigurationPort : BLKPort

@property (nonatomic, assign) SInt16 thresholdOn;
@property (nonatomic, assign) SInt16 thresholdFull;
@property (nonatomic, assign) SInt16 thresholdCrank;
@property (nonatomic, assign) UInt16 stateChangeTimeout;
@property (nonatomic, assign) UInt16 onOffTimeout;
@property (nonatomic, assign) UInt16 ADCTimeout;

- (void)read;
- (void)commit;

@end
