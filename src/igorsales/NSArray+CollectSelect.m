//
//  NSArray+CollectSelect.m
//  CarBeacon
//
//  Created by Igor Sales on 2015-10-22.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import "NSArray+CollectSelect.h"

@implementation NSArray (CollectSelect)

- (NSArray*)select:(BOOL(^)(id obj))block
{
    NSPredicate* pred = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, id bindings) {
        return block(evaluatedObject);
    }];
    
    return [self filteredArrayUsingPredicate:pred];
}

- (NSArray*)collect:(id(^)(id obj))block
{
    NSMutableArray* c = [NSMutableArray new];

    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
        [c addObject:block(obj)];
    }];
    
    return c;
}
@end
