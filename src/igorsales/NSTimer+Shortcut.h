//
//  NSTimer+Shortcut.h
//  CarBeacon
//
//  Created by Igor Sales on 2015-10-29.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSTimer (Shortcut)

+ (NSTimer*)after:(NSTimeInterval)delay do:(void(^)(void))block;

@end
