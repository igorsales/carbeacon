//
//  OTMProximityView.h
//  BTConnTest
//
//  Created by Igor Sales on 2015-10-17.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

typedef enum {
    OTMProximityUnknown   = CLProximityUnknown,
    OTMProximityImmediate = CLProximityImmediate,
    OTMProximityNear      = CLProximityNear,
    OTMProximityFar       = CLProximityFar,
    OTMProximityOutside
} OTMProximity;

@interface OTMProximityView : UIView

@property (nonatomic, assign) OTMProximity proximity;

@end
