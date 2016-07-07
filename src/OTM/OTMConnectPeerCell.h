//
//  OTMConnectPeerCell.h
//  CarBeacon
//
//  Created by Igor Sales on 2015-11-03.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OTMConnectPeerCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView* phoneImageView;
@property (nonatomic, weak) IBOutlet UILabel*     nameLabel;
@property (nonatomic, weak) IBOutlet UILabel*     beaconUUIDLabel;

@end
