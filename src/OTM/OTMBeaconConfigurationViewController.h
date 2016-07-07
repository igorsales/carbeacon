//
//  OTMBeaconConfigurationViewController.h
//  OCTM
//
//  Created by Igor Sales on 2015-09-22.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OTMBeaconConfiguration;
@class BLKManager;
@class BLKDevice;

@interface OTMBeaconConfigurationViewController : UITableViewController

@property (nonatomic, strong) BLKManager* manager;
@property (nonatomic, strong) BLKDevice* device;
@property (nonatomic, strong) OTMBeaconConfiguration* configuration;

@end
