//
//  OTMBeaconConfigurationReadingCell.h
//  BTConnTest
//
//  Created by Igor Sales on 2015-09-22.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OTMBeaconConfigurationReadingCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel* label;
@property (nonatomic, weak) IBOutlet UILabel* readingLabel;
@property (nonatomic, weak) IBOutlet UILabel* unitLabel;

@property (nonatomic, weak) IBOutlet UIProgressView* progressView;

@property (nonatomic, weak)   id        target;
@property (nonatomic, strong) NSString* keyPath;

@end
