//
//  ISDisclosureButton.h
//  CarBeacon
//
//  Created by Igor Sales on 2015-10-18.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    ISDisclosureDirectionUp,
    ISDisclosureDirectionDown
} ISDisclosureDirection;

@interface ISDisclosureButton : UIControl

@property (nonatomic, assign) ISDisclosureDirection arrowDirection;

// operations
- (void)setDisclosureDirection:(ISDisclosureDirection)direction animated:(BOOL)animated;

@end
