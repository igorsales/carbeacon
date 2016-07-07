//
//  OTMBeaconsViewCell.h
//  CarBeacon
//
//  Created by Igor Sales on 2015-10-29.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OTMProximityView;

@interface OTMBeaconsViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIView*           paperView;
@property (nonatomic, weak) IBOutlet OTMProximityView* proximityView;
@property (nonatomic, weak) IBOutlet UILabel*          beaconUUIDLabel;
@property (nonatomic, weak) IBOutlet UITextField*      licensePlateTextField;
@property (nonatomic, weak) IBOutlet UISwitch*         beaconSwitch;
@property (nonatomic, weak) IBOutlet UIButton*         checkButton;
@property (nonatomic, weak) IBOutlet UIButton*         removeButton;

@end
