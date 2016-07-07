//
//  OTMBeaconIdentificationPort.h
//  OTCM
//
//  Created by Igor Sales on 2015-09-22.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import <BLEKit/BLEKit.h>

extern NSString* const kOTMBeaconPortTypeIdentification;

@interface OTMBeaconIdentificationPort : BLKPort

@property (nonatomic, readonly) NSUUID* beaconUUID;
@property (nonatomic, readonly) uint16_t major;
@property (nonatomic, readonly) uint16_t minor;
@property (nonatomic, readonly) int8_t   measuredRSSI;

- (void)read;
- (void)writeBeaconUUID:(NSUUID*)UUID major:(uint16_t)major minor:(uint16_t)minor measuredRSSI:(int8_t)measuredRSSI;

@end
