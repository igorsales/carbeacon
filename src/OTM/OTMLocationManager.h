//
//  OTMLocationManager.h
//  BTConnTest
//
//  Created by Igor Sales on 2015-10-06.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTMLocationMonitor.h"

@class ISNotesManager;
@class OTMDataModel;
@class OTMLocationManager;
@class OTMLocationObservation;

@protocol OTMLocationManagerDelegate <NSObject>

@optional

- (void)locationManager:(OTMLocationManager*)manager enqueuedObservation:(OTMLocationObservation*)observation;
- (void)locationManager:(OTMLocationManager *)manager didSend:(OTMLocationObservation *)observation;

@end

@interface OTMLocationManager : NSObject <OTMLocationMonitorDelegate, NSCoding>

@property (nonatomic, weak) IBOutlet ISNotesManager* notesManager;
@property (nonatomic, weak) IBOutlet OTMDataModel* model;

@property (nonatomic, assign)         NSTimeInterval timeoutToResend;
@property (nonatomic, copy, readonly) NSString* sharingCategory;

@property (nonatomic, weak) IBOutlet id<OTMLocationManagerDelegate> delegate;

- (id)initWithSharingCategory:(NSString*)sharingCategory;

- (void)flush;

@end
