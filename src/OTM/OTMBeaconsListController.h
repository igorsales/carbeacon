//
//  OTMBeaconsListController.h
//  CarBeacon
//
//  Created by Igor Sales on 2015-11-02.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTMBeaconLedger.h"
#import "OTMProximityView.h"
#import "OTMLocationMonitor.h"

@interface OTMBeaconsListController : UIViewController <OTMLocationMonitorProximityViewSource>

@property (nonatomic, strong) OTMBeaconLedger* beacons;

@property (nonatomic, weak)   IBOutlet NSLayoutConstraint* widthConstraint;

- (void)updateBeaconViews;

@end
