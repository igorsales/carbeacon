//
//  ISBTSourcePickerViewController.h
//  BTConnTest
//
//  Created by Igor Sales on 2015-08-27.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ISAudioPortMonitor;

@interface ISBTSourcePickerViewController : UITableViewController

@property (nonatomic, strong) IBOutlet ISAudioPortMonitor* audioPortMonitor;

@end
