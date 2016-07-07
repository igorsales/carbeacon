//
//  ISDismissSegue.m
//  BTConnTest
//
//  Created by Igor Sales on 2015-08-27.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import "ISDismissSegue.h"

@implementation ISDismissSegue

- (void)perform
{
    UIViewController* vc = self.sourceViewController;

    if ([vc respondsToSelector:@selector(commit:)]) {
        [(id<ISCommit>)vc commit:vc];
    }

    [vc.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end

@implementation ISCancelSegue

- (void)perform
{
    UIViewController* vc = self.sourceViewController;

    [vc.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
