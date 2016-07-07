//
//  NSString+URLEncoding.h
//  BTConnTest
//
//  Created by Igor Sales on 2015-10-01.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (URLEncoding)

- (NSString*)URLEncodedString;
- (NSString*)URLDecodedString;

@end
