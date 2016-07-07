//
//  NSBundle+Identifier.h
//  BTConnTest
//
//  Created by Igor Sales on 2015-09-30.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSBundle (Identifier)

+ (NSString*)identifierWithSuffix:(NSString*)suffix;
- (NSString*)identifierWithSuffix:(NSString*)suffix;

@end
