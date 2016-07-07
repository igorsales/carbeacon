//
//  OTMCheck.h
//  CarBeacon
//
//  Created by Igor Sales on 2015-11-07.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    OTMCheckSymbolNone,
    OTMCheckSymbolChecked,
    OTMCheckSymbolX,
    OTMCheckSymbolMinus,
    OTMCheckSymbolPlus
} OTMCheckSymbol;

@interface OTMCheck : UIControl

@property (nonatomic, assign) OTMCheckSymbol symbol;
@property (nonatomic, assign) CGFloat symbolAlpha;

@end
