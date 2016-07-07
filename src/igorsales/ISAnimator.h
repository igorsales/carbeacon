//
//  ISAnimator.h
//  BTConnTest
//
//  Created by Igor Sales on 2015-09-01.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ISAnimator : NSObject

@property (nonatomic, weak)   IBOutlet                       UIView*           targetView;
@property (nonatomic, strong) IBOutletCollection(ISAnimator) NSArray*          nextAnimators;

@property (nonatomic, assign) NSTimeInterval startDelay;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign) NSTimeInterval timeToAnimateNextAnimators;

- (IBAction)prepareToAnimate:(id)sender;
- (IBAction)startAnimating:(id)sender;

- (void)prepareToAnimate;
- (void)animateForDuration:(NSTimeInterval)duration;

@end
