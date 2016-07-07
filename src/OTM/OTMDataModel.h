//
//  OTMDataModel.h
//  BTConnTest
//
//  Created by Igor Sales on 2015-10-03.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OTMPeerSharingLedger;
@class OTMLocationDatabase;
@class OTMBeaconLedger;

@interface OTMDataModel : NSObject <NSCoding>

@property (nonatomic, strong) OTMPeerSharingLedger* ledger;
@property (nonatomic, strong) OTMLocationDatabase*  database;
@property (nonatomic, strong) OTMBeaconLedger*      beacons;

+ (OTMDataModel*)deserializedModel;
- (void)serialize;

@end
