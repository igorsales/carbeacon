//
//  OTMBeaconConfigurationSliderCell.m
//  OCTM
//
//  Created by Igor Sales on 2015-09-22.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import "OTMBeaconConfigurationSliderCell.h"

@interface OTMBeaconConfigurationSliderCell() <UITextFieldDelegate>

@end

@implementation OTMBeaconConfigurationSliderCell

#pragma mark - Accessors

- (void)setKeyPath:(NSString *)keyPath
{
    if (![_keyPath isEqualToString:keyPath]) {
        _keyPath = keyPath;
        [self updateControls];
    }
}

- (void)setTarget:(id)target
{
    if (_target != target) {
        _target = target;
        [self updateControls];
    }
}

#pragma mark - Actions

- (IBAction)minusButtonTapped:(id)sender
{
    self.slider.value = self.slider.value - self.plusOrMinusStep;
    [self sliderValueChanged:self.slider];
}

- (IBAction)plusButtonTapped:(id)sender
{
    self.slider.value = self.slider.value + self.plusOrMinusStep;
    [self sliderValueChanged:self.slider];
}

- (IBAction)sliderValueChanged:(id)sender
{
    self.textField.text = [NSString stringWithFormat:@"%.2f", self.slider.value];
    [self updateTarget];
}

- (IBAction)textFieldValueChanged:(id)sender
{
    self.slider.value = [self.textField.text doubleValue];
    [self updateTarget];
}

#pragma mark - Private

- (void)updateControls
{
    if (!self.keyPath.length || !self.target) {
        return;
    }

    self.slider.value = [[self.target valueForKeyPath:self.keyPath] doubleValue];
    [self sliderValueChanged:self.slider];
}

- (void)updateTarget
{
    [self.target setValue:@(self.slider.value) forKeyPath:self.keyPath];
}

#pragma mark - Operations

- (void)reload
{
    [self updateControls];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];

    return YES;
}

@end
