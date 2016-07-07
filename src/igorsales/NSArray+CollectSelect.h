//
//  NSArray+CollectSelect.h
//  CarBeacon
//
//  Created by Igor Sales on 2015-10-22.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (CollectSelect)

- (NSArray*)select:(BOOL(^)(id obj))block;
- (NSArray*)collect:(id(^)(id obj))block;

@end
