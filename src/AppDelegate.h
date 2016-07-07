//
//  AppDelegate.h
//  BTConnTest
//
//  Created by Igor Sales on 2015-08-26.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTMDataModel.h"
#import "ISNotesManager.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, strong) OTMDataModel* model;
@property (nonatomic, strong) ISNotesManager* notesManager;

@end

