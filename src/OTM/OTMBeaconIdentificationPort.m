//
//  OTMBeaconIdentificationPort.m
//  OTCM
//
//  Created by Igor Sales on 2015-09-22.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import "OTMBeaconIdentificationPort.h"

NSString* const kOTMBeaconPortTypeIdentification = @"kOTMBeaconPortTypeIdentification";

@interface OTMBeaconIdentificationPort()

@property (nonatomic, strong) NSUUID* beaconUUID;
@property (nonatomic, assign) uint16_t major;
@property (nonatomic, assign) uint16_t minor;
@property (nonatomic, assign) int8_t   measuredRSSI;

@end

@implementation OTMBeaconIdentificationPort

- (id)initWithPeripheral:(CBPeripheral *)peripheral andCharacteristic:(CBCharacteristic *)characteristic
{
    if (self = [super initWithPeripheral:peripheral andCharacteristic:characteristic]) {
        [self updateProperties];
    }

    return self;
}

#pragma mark - Private

- (void)updateProperties
{
    if (self.characteristic.value && self.characteristic.value.length >= 16) {
        const unsigned char* bytes = self.characteristic.value.bytes;
        self.beaconUUID = [[NSUUID alloc] initWithUUIDBytes:bytes];
        
        if (self.characteristic.value.length >= 21) {
            self.major = ((uint16_t*)(bytes + 16))[0];
            self.major = ((uint16_t*)(bytes + 16))[1];
            self.measuredRSSI = *(int8_t*)(bytes + 20);
        }
    }
}

#pragma mark - Operations

- (void)read
{
    if (self.operationInProgress) {
        return;
    }
    
    [self.peripheral readValueForCharacteristic:self.characteristic];
    [self startWatchdogTimer];
    
    __weak typeof(self) weakSelf = self;
    self.nextCompletionBlock = ^{
        [weakSelf updateProperties];
    };
    
    self.nextFailureBlock = ^{
    };
}

- (void)writeBeaconUUID:(NSUUID*)UUID major:(uint16_t)major minor:(uint16_t)minor measuredRSSI:(int8_t)measuredRSSI
{
    if (self.operationInProgress) {
        return;
    }
    
    [self startWatchdogTimer];

    NSAssert(self.peripheral, @"nil peripheral");
    NSAssert(UUID != nil, @"nil UUID");
    
    uuid_t UUIDBytes;
    [UUID getUUIDBytes:UUIDBytes];
    NSData* UUIDData = [NSData dataWithBytes:UUIDBytes length:sizeof(uuid_t)];
    
    NSMutableData* data = [UUIDData mutableCopy];
    [data appendBytes:&major length:sizeof(uint16_t)];
    [data appendBytes:&minor length:sizeof(uint16_t)];
    [data appendBytes:&measuredRSSI length:sizeof(int8_t)];
    
    [self.peripheral writeValue:data
              forCharacteristic:self.characteristic
                           type:CBCharacteristicWriteWithResponse];
    
    __weak typeof(self) weakSelf = self;
    self.nextCompletionBlock = ^{
        [weakSelf read];
    };
    
    self.nextFailureBlock = ^{
        // Do nothing
    };
}

@end
