//
//  OTMDataModel.m
//  BTConnTest
//
//  Created by Igor Sales on 2015-10-03.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import "OTMDataModel.h"
#import "OTMPeerSharingLedger.h"
#import "OTMLocationDatabase.h"
#import "OTMBeaconLedger.h"
#import "ISLog.h"

#import <libkern/OSAtomic.h>


@interface OTMDataModel() {
    volatile uint32_t _serializing;
}

@end


@implementation OTMDataModel

#pragma mark - Setup/teardown

- (id)init
{
    if (self = [super init]) {
        self.ledger = [OTMPeerSharingLedger new];
        self.database = [OTMLocationDatabase new];
    }

    return self;
}

- (id)initWithCoder:(NSCoder*)aDecoder
{
    if (self = [super init]) {
        self.ledger = [aDecoder decodeObjectOfClass:[OTMPeerSharingLedger class]
                                         forKey:@"ledger"];
        if (!self.ledger) {
            self.ledger = [OTMPeerSharingLedger new];
        }
        
        self.database = [aDecoder decodeObjectOfClass:[OTMLocationDatabase class]
                                               forKey:@"database"];
        
        if (!self.database) {
            self.database = [OTMLocationDatabase new];
        }
        
        self.beacons = [aDecoder decodeObjectOfClass:[OTMBeaconLedger class]
                                              forKey:@"beacons"];
        if (!self.beacons) {
            self.beacons = [OTMBeaconLedger new];
        }
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:self.ledger   forKey:@"ledger"];
    [encoder encodeObject:self.database forKey:@"database"];
    [encoder encodeObject:self.beacons  forKey:@"beacons"];
}

#pragma mark - Operations

+ (OTMDataModel*)deserializedModel
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    NSData* modelData = [defaults dataForKey:@"kOTMDataModel"];

    id model = [NSKeyedUnarchiver unarchiveObjectWithData:modelData];

    if (!model || ![model isKindOfClass:[OTMDataModel class]]) {
        model = [self new];
    }
    
    return model;
}

- (void)serialize
{
    // To make sure we don't serialize endlessly, we make sure it occurs at most 30 secs after it was requested
    uint32_t isSerializing = OSAtomicOr32Orig(1, &_serializing);
    
    if (!isSerializing) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            ISLogInfo(@"Started serializing model");
            OSAtomicAnd32(0, &_serializing);
            NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
            
            NSData* modelData = [NSKeyedArchiver archivedDataWithRootObject:self];
            [defaults setObject:modelData forKey:@"kOTMDataModel"];
            
            [defaults synchronize];
            ISLogInfo(@"Finished serializing model");
        });
    }
}

@end
