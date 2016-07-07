//
//  OTMBeaconConfigurationSliderCell.h
//  OCTM
//
//  Created by Igor Sales on 2015-09-22.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OTMBeaconConfigurationSliderCell : UITableViewCell

@property (nonatomic, assign) CGFloat plusOrMinusStep;
@property (nonatomic, assign) CGFloat value;

@property (nonatomic, weak) IBOutlet UIButton*    minusButton;
@property (nonatomic, weak) IBOutlet UISlider*    slider;
@property (nonatomic, weak) IBOutlet UIButton*    plusButton;
@property (nonatomic, weak) IBOutlet UILabel*     label;
@property (nonatomic, weak) IBOutlet UILabel*     unitLabel;
@property (nonatomic, weak) IBOutlet UITextField* textField;

@property (nonatomic, strong) NSString* keyPath;
@property (nonatomic, weak)   id target;

- (IBAction)minusButtonTapped:(id)sender;
- (IBAction)plusButtonTapped:(id)sender;
- (IBAction)sliderValueChanged:(id)sender;
- (IBAction)textFieldValueChanged:(id)sender;

- (void)reload;

@end
