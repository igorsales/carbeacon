//
//  OTMLocationObservation.m
//  BTConnTest
//
//  Created by Igor Sales on 2015-10-04.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import "OTMLocationObservation.h"
#import "NSDate+ServerDate.h"
#import "ISLog.h"

@implementation OTMLocationObservation

- (id)initWithLocation:(CLLocation *)location
{
    return [self initWithLocation:location fromUserId:nil];
}

- (id)initWithLocation:(CLLocation *)location fromUserId:(NSString *)fromUserId
{
    if (self = [super init]) {
        _location = location;
        _fromUserId = [fromUserId copy];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        _location          = [aDecoder decodeObjectForKey:@"location"];
        _lastSendTimestamp = [aDecoder decodeObjectForKey:@"lastSendTimestamp"];
        _numberOfSendTries = [aDecoder decodeIntegerForKey:@"numberOfSendTries"];
        _sentSuccessfully  = [aDecoder decodeBoolForKey:@"sentSuccessfully"];
        _fromUserId        = [aDecoder decodeObjectForKey:@"fromUserId"];
        _beaconUUIDString  = [aDecoder decodeObjectForKey:@"beaconUUIDString"];
    }

    return self;
}

- (id)initWithJSONData:(NSData *)data from:(NSString *)fromUserId
{
    if (self = [super init]) {
        __autoreleasing NSError* error = nil;
        NSDictionary* coords = [NSJSONSerialization JSONObjectWithData:data
                                                               options:0
                                                                 error:&error];
        
        if (error) {
            ISLogDebug(@"Could not parse JSON from message %@", error);
            return nil;
        }
        
        NSNumber* lat = coords[@"lat"];
        NSNumber* lon = coords[@"lon"];
        
        if (!lat || !lon) {
            ISLogDebug(@"Could not create observation without coordinates");
            return nil;
        }
        
        NSDate* ts = [NSDate dateFromTimestampString:coords[@"ts"]];
        if (!ts) {
            ISLogDebug(@"Could not parse observation timestamp");
            return nil;
        }
        
        NSString* beaconUUIDString = coords[@"beaconUUID"];
        if ([beaconUUIDString isKindOfClass:[NSString class]]) {
            self.beaconUUIDString = beaconUUIDString;
        }
        
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(lat.doubleValue,
                                                                  lon.doubleValue);

        self.location = [[CLLocation alloc] initWithCoordinate:coord
                                                      altitude:[coords[@"alt"] doubleValue]
                                            horizontalAccuracy:[coords[@"horAcc"] doubleValue]
                                              verticalAccuracy:[coords[@"vertAcc"] doubleValue]
                                                     timestamp:ts];
        
        self.fromUserId = fromUserId;
    }

    return self;
}

- (NSData*)JSONData
{
    NSMutableDictionary* what = [NSMutableDictionary new];
    if (self.location.coordinate.latitude) {
        what[@"lat"] = @(self.location.coordinate.latitude);
        what[@"lon"] = @(self.location.coordinate.longitude);
    }
    
    if (self.location.altitude) {
        what[@"alt"] = @(self.location.altitude);
    }
    
    if (self.location.horizontalAccuracy) {
        what[@"horAcc"] = @(self.location.horizontalAccuracy);
    }
    
    if (self.location.horizontalAccuracy) {
        what[@"vertAcc"] = @(self.location.verticalAccuracy);
    }
    
    if (self.location.timestamp) {
        what[@"ts"] = [self.location.timestamp timestampString];
    }
    
    if (self.location.floor) {
        what[@"floorLevel"] = @(self.location.floor.level);
    }
    
    if (self.beaconUUIDString.length) {
        what[@"beaconUUID"] = self.beaconUUIDString;
    }
    
    __autoreleasing NSError* error = nil;
    NSData* JSONData = [NSJSONSerialization dataWithJSONObject:what
                                                       options:0
                                                         error:&error];
    
    if (error) {
        ISLogError(@"Error creating JSON data from observation! %@", error);
    }
    
    return JSONData;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.location forKey:@"location"];
    [aCoder encodeObject:self.lastSendTimestamp forKey:@"lastSendTimestamp"];
    [aCoder encodeInteger:self.numberOfSendTries forKey:@"numberOfSendTries"];
    [aCoder encodeBool:self.sentSuccessfully forKey:@"sentSuccessfully"];
    [aCoder encodeObject:self.fromUserId forKey:@"fromUserId"];
    [aCoder encodeObject:self.beaconUUIDString forKey:@"beaconUUIDString"];
}

- (NSUInteger)hash
{
    return self.location.hash + self.lastSendTimestamp.hash + self.numberOfSendTries * 10 + self.sentSuccessfully;
}

- (BOOL)isEqual:(OTMLocationObservation*)obs
{
    if (![obs isKindOfClass:[OTMLocationObservation class]]) {
        return NO;
    }
    
    if ((self.fromUserId && !obs.fromUserId) || (!self.fromUserId && obs.fromUserId)) {
        return NO;
    }
    
    if (self.fromUserId && obs.fromUserId && ![self.fromUserId isEqualToString:obs.fromUserId]) {
        return NO;
    }
    
    if ((self.beaconUUIDString && !obs.beaconUUIDString) || (!self.beaconUUIDString && self.beaconUUIDString)) {
        return NO;
    }
    
    if (self.beaconUUIDString && obs.beaconUUIDString && ![self.beaconUUIDString isEqualToString:obs.beaconUUIDString]) {
        return NO;
    }

    if ((self.location && !obs.location) || (!self.location && obs.location)) {
        return NO;
    }

    if (self.location && obs.location && ![self.location isEqual:obs.location]) {
        return NO;
    }

    if ((self.lastSendTimestamp && !obs.lastSendTimestamp) ||
        (!self.lastSendTimestamp && obs.lastSendTimestamp)) {
        return NO;
    }
    
    if ((self.lastSendTimestamp && obs.lastSendTimestamp) &&
        ![self.lastSendTimestamp isEqualToDate:obs.lastSendTimestamp]) {
        return NO;
    }

    return self.numberOfSendTries == obs.numberOfSendTries &&
           self.sentSuccessfully == obs.sentSuccessfully;
}

@end
