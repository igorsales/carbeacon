//
//  OTMBeaconsViewController.h
//  CarBeacon
//
//  Created by Igor Sales on 2015-10-28.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OTMBeaconLedger;

@interface OTMBeaconsViewController : UITableViewController

@property (nonatomic, strong) OTMBeaconLedger* beacons;

- (IBAction)showCarBeaconConfiguration:(id)sender;

@end
