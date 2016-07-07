//
//  NSTimer+Shortcut.m
//  CarBeacon
//
//  Created by Igor Sales on 2015-10-29.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import "NSTimer+Shortcut.h"

@interface _NSTimerObject : NSObject

@property (nonatomic, copy) void(^block)(void);

@end

@implementation _NSTimerObject

- (void)timerFired:(NSTimer*)timer
{
    self.block();
}

@end

@implementation NSTimer (Shortcut)

+ (NSTimer*)after:(NSTimeInterval)delay do:(void(^)(void))block
{
    _NSTimerObject* to = [_NSTimerObject new];
    to.block = block;
    
    return [NSTimer scheduledTimerWithTimeInterval:delay
                                            target:to
                                          selector:@selector(timerFired:)
                                          userInfo:nil
                                           repeats:NO];
}

@end
