//
//  OTMBeaconConfigurationPort.m
//  OTCM
//
//  Created by Igor Sales on 2015-09-22.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import "OTMBeaconConfigurationPort.h"

NSString* const kOTMBeaconPortTypeConfiguration = @"kOTMBeaconPortTypeConfiguration";

@interface OTMBeaconConfigurationPort() {
    struct {
        union {
            UInt16 unsignedValue[6];
            SInt16 signedValue[6];
        };

        union {
            UInt16 unsignedCache[6];
            SInt16 signedCache[6];
        };
    } _rawData;
}

@end

@implementation OTMBeaconConfigurationPort

#pragma mark - Accessors

- (SInt16)thresholdOn
{
    return _rawData.signedValue[0];
}

- (void)setThresholdOn:(SInt16)thresholdOn
{
    _rawData.signedCache[0] = thresholdOn;
}

- (SInt16)thresholdFull
{
    return _rawData.signedValue[1];
}

- (void)setThresholdFull:(SInt16)thresholdFull
{
    _rawData.signedCache[1] = thresholdFull;
}

- (SInt16)thresholdCrank
{
    return _rawData.signedValue[2];
}

- (void)setThresholdCrank:(SInt16)thresholdCrank
{
    _rawData.signedCache[2] = thresholdCrank;
}

- (UInt16)stateChangeTimeout
{
    return _rawData.unsignedValue[3];
}

- (void)setStateChangeTimeout:(UInt16)stateChangeTimeout
{
    _rawData.unsignedCache[3] = stateChangeTimeout;
}

- (UInt16)onOffTimeout
{
    return _rawData.unsignedValue[4];
}

- (void)setOnOffTimeout:(UInt16)onOffTimeout
{
    _rawData.unsignedCache[4] = onOffTimeout;
}

- (UInt16)ADCTimeout
{
    return _rawData.unsignedValue[5];
}

- (void)setADCTimeout:(UInt16)ADCTimeout
{
    _rawData.unsignedCache[5] = ADCTimeout;
}

#pragma mark - Operations

- (void)read
{
    if (self.operationInProgress) {
        return;
    }
    
    [self.peripheral readValueForCharacteristic:self.characteristic];
    [self startWatchdogTimer];
    
    void* dataPtr      = _rawData.unsignedValue;
    void* dataCachePtr = _rawData.unsignedCache;
    
    __weak typeof(self) weakSelf = self;
    self.nextCompletionBlock = ^{
        
        UInt16 bits[6];
        [weakSelf.characteristic.value getBytes:&bits length:sizeof(bits)];
        
        memcpy(dataCachePtr, bits, sizeof(_rawData.unsignedCache));
        memcpy(dataPtr,      bits, sizeof(_rawData.unsignedCache));
    };
    
    self.nextFailureBlock = ^{
    };
}

- (void)commit
{
    if (self.operationInProgress) {
        return;
    }
    
    if (memcmp(_rawData.unsignedValue, _rawData.unsignedCache, sizeof(_rawData.unsignedCache)) == 0) {
        // Nothing new to write, so bail
        return;
    }
    
    // Now copy, and send it over.
    memcpy(_rawData.unsignedValue, _rawData.unsignedCache, sizeof(_rawData.unsignedCache));
    
    [self writeBits];
    [self startWatchdogTimer];
}

- (void)writeBits
{
    NSAssert(self.peripheral, @"nil peripheral");
    
    NSData* bitsData = [NSData dataWithBytes:_rawData.unsignedValue length:sizeof(_rawData.unsignedValue)];
    
    [self.peripheral writeValue:bitsData
              forCharacteristic:self.characteristic
                           type:CBCharacteristicWriteWithResponse]; // TODO: Check if can be without response
    
    __weak typeof(self) weakSelf = self;
    void* dataPtr      = _rawData.unsignedValue;
    void* dataCachePtr = _rawData.unsignedCache;
    
    self.nextCompletionBlock = ^{
        if (weakSelf.operationInProgress) {
            if (memcmp(dataPtr, dataCachePtr, sizeof(_rawData.unsignedCache)) != 0) {
                
                memcpy(dataPtr, dataCachePtr, sizeof(_rawData.unsignedCache));
                [weakSelf writeBits];
                [weakSelf startWatchdogTimer];
            }
        }
    };
    
    self.nextFailureBlock = ^{
        // Do nothing
    };
}


@end
