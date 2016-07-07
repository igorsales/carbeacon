//
//  OTMDateAndTimeViewController.h
//  CarBeacon
//
//  Created by Igor Sales on 2015-10-18.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OTMLocationDatabase.h"

@class OTMDateAndTimeViewController;


@protocol OTMDateAndTimePickerProtocol <NSObject>

- (void)dateAndTimePicker:(OTMDateAndTimeViewController*)picker didPickObservation:(OTMLocationObservation*)observation;

@end


@interface OTMDateAndTimeViewController : UITableViewController

@property (nonatomic, strong) id<OTMObservationDataSource> dataSource;

@property (nonatomic, weak)   id<OTMDateAndTimePickerProtocol> delegate;

// operations
- (void)slideFromRightOntoViewController:(UIViewController*)viewController view:(UIView*)view;
- (void)slideOut;

@end
