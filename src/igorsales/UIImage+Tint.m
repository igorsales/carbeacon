//
//  UIImage+Tint.m
//  CarBeacon
//
//  Created by Igor Sales on 2015-10-28.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import "UIImage+Tint.h"
#import <QuartzCore/QuartzCore.h>

@implementation UIImage (Tint)

- (UIImage*)imageTintedWithColor:(UIColor *)color
{
    UIGraphicsBeginImageContext(self.size);
    
    [self drawAtPoint:CGPointMake(0, 0)
            blendMode:kCGBlendModeNormal
                alpha:1.0];
    
    [color setFill];
    UIRectFillUsingBlendMode(CGRectMake(0, 0, self.size.width, self.size.height),
                             kCGBlendModeSourceIn);
    
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

@end
