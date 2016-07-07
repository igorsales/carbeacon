//
//  ISDisclosureButton.m
//  CarBeacon
//
//  Created by Igor Sales on 2015-10-18.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import "ISDisclosureButton.h"

@interface ISDisclosureButton()

@property (nonatomic, weak) CAShapeLayer* indicatorLayer;

@end

@implementation ISDisclosureButton

#pragma mark - Setup/teardown

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self setup];
    }

    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }

    return self;
}

- (void)setup
{
    CAShapeLayer* layer = [CAShapeLayer new];
    
    layer.frame = CGRectMake(0, 0, 18, 12);
    
    CGFloat middleX = layer.bounds.size.width / 2;
    
    UIBezierPath* path = [UIBezierPath new];
    
    [path moveToPoint:CGPointMake(middleX, 0)];
    [path addLineToPoint:CGPointMake(layer.bounds.size.width, layer.bounds.size.height)];
    [path addLineToPoint:CGPointMake(0, layer.bounds.size.height)];
    [path closePath];
    
    layer.path = path.CGPath;

    layer.strokeColor = [self.tintColor colorWithAlphaComponent:0.73].CGColor;
    layer.fillColor   = [self.tintColor colorWithAlphaComponent:0.37].CGColor;
    layer.lineWidth   = 2.2;
    layer.lineJoin    = kCALineJoinRound;
    layer.lineCap     = kCALineCapRound;
    
    layer.position = CGPointMake(CGRectGetMidX(self.layer.bounds), CGRectGetMidY(self.layer.bounds));

    [self.layer addSublayer:layer];
    self.indicatorLayer = layer;
    
    self.layer.masksToBounds   = YES;
    self.layer.borderColor     = self.tintColor.CGColor;
    self.layer.cornerRadius    = 4.0;
    self.layer.borderWidth     = 1.0;
    self.layer.backgroundColor = [self.tintColor colorWithAlphaComponent:0.17].CGColor;
}

#pragma mark - Operations

- (void)setDisclosureDirection:(ISDisclosureDirection)direction animated:(BOOL)animated
{
    self.arrowDirection = direction;
    
    if (animated) {
        [UIView beginAnimations:nil context:nil];
    }
    
    CATransform3D xform = CATransform3DIdentity;
    switch (direction) {
        case ISDisclosureDirectionUp: break;
            break;
            
        case ISDisclosureDirectionDown:
            xform = CATransform3DMakeRotation(M_PI, 0, 0, 1.0);
            break;
            
        default:
            break;
    }
    self.indicatorLayer.transform = xform;
    
    if (animated) {
        [UIView commitAnimations];
    }
}

@end
