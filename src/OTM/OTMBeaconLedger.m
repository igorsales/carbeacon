//
//  OTMBeaconLedger.m
//  CarBeacon
//
//  Created by Igor Sales on 2015-10-29.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import "OTMBeaconLedger.h"
#import "NSArray+CollectSelect.h"

@interface OTMBeaconLedger()

@property (nonatomic, strong) NSMutableDictionary* beaconToOptionsMap;

@end

@implementation OTMBeaconLedger

#pragma mark - Setup/Teardown

- (id)init
{
    if (self = [super init]) {
        [self setup];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        self.beaconToOptionsMap = [aDecoder decodeObjectOfClass:[NSMutableDictionary class]
                                                         forKey:@"beaconToOptionsMap"];
        if (!self.beaconToOptionsMap) {
            [self setup];
        }
    }
    
    return self;
}

- (void)setup
{
    self.beaconToOptionsMap = [NSMutableDictionary new];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.beaconToOptionsMap forKey:@"beaconToOptionsMap"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    // use archive/unarchive to make deep copy
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:self];
    
    if (!data) {
        return nil;
    }
    
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

#pragma mark - Operations

- (void)addBeaconUUID:(NSString*)beaconUUID withOptions:(NSDictionary*)options
{
    self.beaconToOptionsMap[beaconUUID] = options ? options : @{};
}

- (void)removeBeaconUUID:(NSString*)beaconUUID
{
    [self.beaconToOptionsMap removeObjectForKey:beaconUUID];
}

- (NSArray*)beaconUUIDStrings
{
    return self.beaconToOptionsMap.allKeys;
}

- (NSDictionary*)optionsForBeaconUUID:(NSString*)beaconUUID
{
    return self.beaconToOptionsMap[beaconUUID];
}

@end
