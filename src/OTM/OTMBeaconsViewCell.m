//
//  OTMBeaconsViewCell.m
//  CarBeacon
//
//  Created by Igor Sales on 2015-10-29.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import "OTMBeaconsViewCell.h"
#import "OTMCheck.h"

@interface OTMBeaconsViewCell() <UITextFieldDelegate>

@end

@implementation OTMBeaconsViewCell

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];

    return YES;
}

- (IBAction)toggle:(OTMCheck*)c
{
    switch (c.symbol) {
        case OTMCheckSymbolNone: c.symbol = OTMCheckSymbolChecked; break;
        case OTMCheckSymbolChecked: c.symbol = OTMCheckSymbolX; break;
        case OTMCheckSymbolX: c.symbol = OTMCheckSymbolPlus; break;
        case OTMCheckSymbolPlus: c.symbol = OTMCheckSymbolMinus; break;
        case OTMCheckSymbolMinus: c.symbol = OTMCheckSymbolNone; break;

        default:
            break;
    }
}

@end
