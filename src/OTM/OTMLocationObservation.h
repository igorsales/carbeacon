//
//  OTMLocationObservation.h
//  BTConnTest
//
//  Created by Igor Sales on 2015-10-04.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface OTMLocationObservation : NSObject <NSCoding>

@property (atomic, strong) CLLocation* location;
@property (atomic, copy)   NSDate*     lastSendTimestamp;
@property (atomic, assign) NSInteger   numberOfSendTries;
@property (atomic, assign) BOOL        sentSuccessfully;

@property (atomic, copy)   NSString*   fromUserId;
@property (atomic, copy)   NSString*   beaconUUIDString;

// transient
@property (atomic, assign) BOOL        sending;

- (id)initWithLocation:(CLLocation*)location;
- (id)initWithLocation:(CLLocation*)location fromUserId:(NSString*)fromUserId;
- (id)initWithJSONData:(NSData*)data from:(NSString*)fromUserId;

- (NSData*)JSONData;

@end
