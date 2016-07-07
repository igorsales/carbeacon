//
//  OTMBeaconConfigurationService.h
//  CarBeacon
//
//  Created by Igor Sales on 2015-09-22.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import <BLEKit/BLEKit.h>

@interface OTMBeaconConfigurationService : BLKService

@property (nonatomic, readonly) CBCharacteristic* voltagesAndTimeoutsCharacteristic;
@property (nonatomic, readonly) CBCharacteristic* beaconUUIDCharacteristic;

@end
