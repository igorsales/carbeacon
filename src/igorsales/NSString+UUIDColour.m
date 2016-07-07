//
//  NSString+UUIDColour.m
//  BTConnTest
//
//  Created by Igor Sales on 2015-10-15.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import "NSString+UUIDColour.h"

@implementation NSString (UUIDColour)

- (UIColor*)UUIDColor
{
    uint32_t RGBA = 0x00;

    NSMutableString* string = [self mutableCopy];
    [string replaceOccurrencesOfString:@"-" withString:@"" options:0 range:NSMakeRange(0, string.length)];
    
    unsigned int idx = 8;
    while (string.length > idx) {
        [string insertString:@" " atIndex:idx];
        idx += 9;
    }
    
    NSScanner* scanner = [NSScanner scannerWithString:string];
    
    unsigned int hex = 0;
    while([scanner scanHexInt:&hex]) {
        RGBA = RGBA ^ hex;
    }
    
    return [UIColor colorWithRed:((RGBA >> 24) & 0xFF) / 255.0
                           green:((RGBA >> 16) & 0xFF) / 255.0
                            blue:((RGBA >> 8)  & 0xFF) / 255.0
                           alpha:1.0];
}

@end
