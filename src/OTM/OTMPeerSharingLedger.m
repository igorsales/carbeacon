//
//  OTMPeerSharingLedger.m
//  BTConnTest
//
//  Created by Igor Sales on 2015-10-03.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import "OTMPeerSharingLedger.h"

@interface OTMPeerSharingLedger()

@property (nonatomic, strong) NSMutableDictionary* categoryToUserMap;

@end

@implementation OTMPeerSharingLedger

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
        self.categoryToUserMap = [aDecoder decodeObjectOfClass:[NSMutableDictionary class]
                                                        forKey:@"categoryToUserMap"];
        if (!self.categoryToUserMap) {
            [self setup];
        }
    }
    
    return self;
}

- (void)setup
{
    self.categoryToUserMap = [NSMutableDictionary new];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.categoryToUserMap forKey:@"categoryToUserMap"];
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

- (void)allowUserId:(NSString*)userId asReceiverOf:(NSString*)category withOptions:(NSDictionary*)options
{
    NSAssert(category, @"category cannot be nil");
    NSAssert(userId, @"userId cannot be nil");

    NSMutableDictionary* categoryMap = self.categoryToUserMap[category];
    if (!categoryMap) {
        categoryMap = [NSMutableDictionary new];
        self.categoryToUserMap[category] = categoryMap;
    }

    categoryMap[userId] = options ? options : [NSNull null];
}

- (void)preventUser:(NSString*)userId fromReceiving:(NSString*)category
{
    NSAssert(category, @"category cannot be nil");
    NSAssert(userId, @"userId cannot be nil");

    NSMutableDictionary* categoryMap = self.categoryToUserMap[category];
    if (!categoryMap) {
        return; // no need to create one
    }

    categoryMap[userId] = nil;
    
    if (categoryMap.allKeys.count == 0) {
        self.categoryToUserMap[category] = nil;
    }
}

- (NSArray*)usersAllowedToReceive:(NSString*)category
{
    NSAssert(category, @"category cannot be nil");

    NSMutableDictionary* categoryMap = self.categoryToUserMap[category];
    if (!categoryMap) {
        return nil; // no need to create one
    }
    
    return categoryMap.allKeys;
}

- (NSDictionary*)optionsToReceive:(NSString*)category forUser:(NSString*)userId
{
    NSAssert(category, @"category cannot be nil");
    NSAssert(userId, @"userId cannot be nil");

    NSMutableDictionary* categoryMap = self.categoryToUserMap[category];
    if (!categoryMap) {
        return nil; // no need to create one
    }
    
    id options = categoryMap[userId];
    
    if (![options isEqual:[NSNull null]]) {
        return options;
    }
    
    return nil;
}


@end
