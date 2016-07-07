//
//  NSDate+ServerDate.h
//  CarBeacon
//
//  Created by Igor Sales on 2015-10-23.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (ServerDate)

+ (NSDate*)dateFromTimestampString:(NSString*)tsString;
- (NSString*)timestampString;

@end
