//
//  OTMBeaconConfigurationService.m
//  CarBeacon
//
//  Created by Igor Sales on 2015-09-22.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import "OTMBeaconConfigurationService.h"
#import "OTMBeaconConfigurationPort.h"
#import "OTMBeaconIdentificationPort.h"

@interface OTMBeaconConfigurationService()

@property (nonatomic, strong) CBUUID*           voltagesAndTimeoutsUUID;
@property (nonatomic, strong) CBCharacteristic* voltagesAndTimeoutsCharacteristic;

@property (nonatomic, strong) CBUUID*           beaconUUIDUUID;
@property (nonatomic, strong) CBCharacteristic* beaconUUIDCharacteristic;

@end

@implementation OTMBeaconConfigurationService

- (BOOL)parseServiceCharacteristics:(CBService *)service
{
    BOOL r = [super parseServiceCharacteristics:service];
    
    if (r) {
        if (self.voltagesAndTimeoutsCharacteristic) {
            // Read constants
            [service.peripheral readValueForCharacteristic:self.voltagesAndTimeoutsCharacteristic];
        }
        
        if (self.beaconUUIDCharacteristic) {
            // Read UUID
            [service.peripheral readValueForCharacteristic:self.beaconUUIDCharacteristic];
        }
    }
    
    return r;
}

- (BOOL)shouldMakeServiceUsable
{
    return self.voltagesAndTimeoutsCharacteristic != nil && self.beaconUUIDCharacteristic != nil;
}

- (id)portOfType:(NSString*)type atIndex:(NSInteger)index subIndex:(NSInteger)subIndex withOptions:(NSDictionary *)options
{
    if ([type isEqualToString:kOTMBeaconPortTypeConfiguration]) {
        if (self.voltagesAndTimeoutsCharacteristic) {
            OTMBeaconConfigurationPort* port = [[OTMBeaconConfigurationPort alloc]
                                           initWithPeripheral:self.service.peripheral
                                           andCharacteristic:self.voltagesAndTimeoutsCharacteristic];
            [self registerListener:port
             forCharacteristicUUID:self.voltagesAndTimeoutsCharacteristic.UUID];
            return port;
        }
    } else if ([type isEqualToString:kOTMBeaconPortTypeIdentification]) {
        if (self.beaconUUIDCharacteristic) {
            OTMBeaconIdentificationPort* port = [[OTMBeaconIdentificationPort alloc]
                                                 initWithPeripheral:self.service.peripheral
                                                 andCharacteristic:self.beaconUUIDCharacteristic];
            [self registerListener:port
             forCharacteristicUUID:self.beaconUUIDCharacteristic.UUID];
            return port;
        }
    }
    
    return nil;
}

@end
