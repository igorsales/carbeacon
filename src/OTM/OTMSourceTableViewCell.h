//
//  OTMSourceTableViewCell.h
//  CarBeacon
//
//  Created by Igor Sales on 2015-10-23.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OTMProximityView;

@interface OTMSourceTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView* phoneImageView;
@property (nonatomic, weak) IBOutlet OTMProximityView* proximityView;
@property (nonatomic, weak) IBOutlet UILabel* nameLabel;
@property (nonatomic, weak) IBOutlet UILabel* beaconUUIDLabel;

@end
