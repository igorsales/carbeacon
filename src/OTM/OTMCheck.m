//
//  OTMCheck.m
//  CarBeacon
//
//  Created by Igor Sales on 2015-11-07.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import "OTMCheck.h"
#import <QuartzCore/QuartzCore.h>

@interface OTMCheck()

@property (nonatomic, weak) UITouch* fingerTouch;

@property (nonatomic, weak) UILabel* symbolLabel;
@property (nonatomic, weak) UILabel* backupSymbolLabel;

@end

@implementation OTMCheck

#pragma mark - setup/teardown

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

#pragma mark - Accessors

@synthesize symbol = _symbol;
@synthesize symbolAlpha = _symbolAlpha;

- (void)setSymbol:(OTMCheckSymbol)symbol
{
    [self setSymbol:symbol animated:NO];
}

- (void)setSymbol:(OTMCheckSymbol)symbol animated:(BOOL)animated
{
    if (_symbol != symbol) {
        _symbol = symbol;
        [self updateSymbolLayerAnimated:animated];
    }
}

- (void)setSymbolAlpha:(CGFloat)symbolAlpha
{
    [self setSymbolAlpha:symbolAlpha animated:NO];
}

- (void)setSymbolAlpha:(CGFloat)symbolAlpha animated:(BOOL)animated
{
    if (_symbolAlpha != symbolAlpha) {
        _symbolAlpha = symbolAlpha;
        [self updateSymbolLayerAnimated:animated];
    }
}

#pragma mark - Private

- (void)setup
{
    self.symbolAlpha = 1.0;

    self.layer.masksToBounds = YES;
    self.layer.cornerRadius  = MIN(self.bounds.size.width, self.bounds.size.height) / 2;
    self.layer.borderWidth   = 2.2;
    self.layer.borderColor   = self.tintColor.CGColor;
    
    if (!self.symbolLabel) {
        UILabel* symbolLabel = [[UILabel alloc] initWithFrame:self.bounds];
        [self addSubview:symbolLabel];
        self.symbolLabel = symbolLabel;
        self.symbolLabel.font = [UIFont fontWithName:@"Courier-Bold" size:self.bounds.size.height * .75];
        self.symbolLabel.textAlignment = NSTextAlignmentCenter;
    }
    
    self.symbolLabel.frame = self.bounds;

    if (!self.backupSymbolLabel) {
        UILabel* symbolLabel = [[UILabel alloc] initWithFrame:self.bounds];
        [self addSubview:symbolLabel];
        self.backupSymbolLabel = symbolLabel;
        self.backupSymbolLabel.hidden = YES;
        self.backupSymbolLabel.font = self.symbolLabel.font;
        self.backupSymbolLabel.textAlignment = self.symbolLabel.textAlignment;
    }
    
    self.backupSymbolLabel.frame = self.bounds;
}

- (void)updateSymbolLayerAnimated:(BOOL)animated
{
    CGFloat animationDuration = animated ? 0.3 : 0.0;
    
    NSString* text = @" ";
    UIColor* colour = [UIColor clearColor];
    switch (self.symbol) {
        default:
        case OTMCheckSymbolNone:    break;
            
        case OTMCheckSymbolX:       text = @"X"; colour = [UIColor redColor]; break;
            
        case OTMCheckSymbolChecked: text = @"\u2713"; colour = [UIColor greenColor]; break;
            
        case OTMCheckSymbolMinus:   text = @"-"; colour = [UIColor redColor]; break;
            
        case OTMCheckSymbolPlus:    text = @"+"; colour = [UIColor greenColor]; break;
    }
    
    self.backupSymbolLabel.text      = text;
    self.backupSymbolLabel.alpha     = 0.0;
    self.backupSymbolLabel.hidden    = NO;
    self.backupSymbolLabel.textColor = colour;
    
    [self bringSubviewToFront:self.backupSymbolLabel];
    
    [UIView animateWithDuration:animationDuration
                     animations:^{
                         self.backupSymbolLabel.alpha = self.symbolAlpha;
                         self.symbolLabel.alpha = 0.0;
                     } completion:^(BOOL finished) {
                         UILabel* aux = self.backupSymbolLabel;
                         self.backupSymbolLabel = self.symbolLabel;
                         self.symbolLabel = aux;
                         
                         self.backupSymbolLabel.hidden = YES;
                     }];
}

#pragma mark - Event tracking

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent *)event
{
    if (self.fingerTouch) {
        return;
    }
    
    self.fingerTouch = touches.anyObject;
    [self sendActionsForControlEvents:UIControlEventTouchDown];
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent *)event
{
    if ([touches containsObject:self.fingerTouch]) {
        [self sendActionsForControlEvents:UIControlEventTouchUpInside];
        self.fingerTouch = nil;
    }
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent *)event
{
    if ([touches containsObject:self.fingerTouch]) {
        [self sendActionsForControlEvents:UIControlEventTouchUpInside];
        self.fingerTouch = nil;
    }
}

@end
