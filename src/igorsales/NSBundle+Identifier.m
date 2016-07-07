//
//  NSBundle+Identifier.m
//  BTConnTest
//
//  Created by Igor Sales on 2015-09-30.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import "NSBundle+Identifier.h"

@implementation NSBundle (Identifier)

- (NSString*)identifierWithSuffix:(NSString*)suffix
{
#ifdef IS_UNDER_UNIT_TEST
    return [@"ca.igorsales.unittest" stringByAppendingFormat:@".%@", suffix];
#else
    return [[self bundleIdentifier] stringByAppendingFormat:@".%@", suffix];
#endif
}

+ (NSString*)identifierWithSuffix:(NSString *)suffix
{
    return [[NSBundle mainBundle] identifierWithSuffix:suffix];
}

@end
