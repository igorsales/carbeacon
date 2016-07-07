//
//  OTMBeaconLedger.h
//  CarBeacon
//
//  Created by Igor Sales on 2015-10-29.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTMBeaconLedger : NSObject <NSCopying, NSCoding>

- (void)addBeaconUUID:(NSString*)beaconUUID withOptions:(NSDictionary*)options;
- (void)removeBeaconUUID:(NSString*)beaconUUID;

- (NSArray*)beaconUUIDStrings;
- (NSDictionary*)optionsForBeaconUUID:(NSString*)beaconUUID;

@end
