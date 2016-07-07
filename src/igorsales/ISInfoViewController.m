//
//  ISInfoViewController.m
//  BTConnTest
//
//  Created by Igor Sales on 2015-09-01.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import "ISInfoViewController.h"
#import "ISAnimator.h"

@interface ISInfoViewController ()

@end

@implementation ISInfoViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.firstAnimator prepareToAnimate:self];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self.firstAnimator startAnimating:self];
}

@end
