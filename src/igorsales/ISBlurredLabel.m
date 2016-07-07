//
//  ISBlurredLabel.m
//  BTConnTest
//
//  Created by Igor Sales on 2015-08-30.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import "ISBlurredLabel.h"

@implementation ISBlurredLabel

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void) drawTextInRect:(CGRect)rect
{
    self.clipsToBounds = NO;
    CGSize myShadowOffset = CGSizeMake(0, 1);
    CGFloat myColorValues[] = {0.073, 0.073, 0.073, 1};
    
    CGContextRef myContext = UIGraphicsGetCurrentContext();
    CGContextSaveGState(myContext);
    
    CGColorSpaceRef myColorSpace = CGColorSpaceCreateDeviceRGB();
    CGColorRef myColor = CGColorCreate(myColorSpace, myColorValues);
    CGContextSetShadowWithColor (myContext, myShadowOffset, 5.5, myColor);
    
    [super drawTextInRect:rect];
    
    CGColorRelease(myColor);
    CGColorSpaceRelease(myColorSpace);
    
    CGContextRestoreGState(myContext);
}

@end
