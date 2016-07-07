//
//  ISDismissSegue.h
//  BTConnTest
//
//  Created by Igor Sales on 2015-08-27.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ISCommit <NSObject>

- (IBAction)commit:(id)sender;

@end

@interface ISDismissSegue : UIStoryboardSegue

@end

@interface ISCancelSegue : UIStoryboardSegue

@end
