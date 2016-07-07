//
//  AppDelegate.m
//  CarBeacon
//
//  Created by Igor Sales on 2015-08-26.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import "AppDelegate.h"
#import "ISNotesManager.h"
#import "ISLog.h"

#import <BLEKit/BLEKit.h>

#import <ExternalAccessory/ExternalAccessory.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface AppDelegate ()

@property (nonatomic, retain) AVAudioPlayer* audioPlayer;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSBundle* bundle = [NSBundle bundleForClass:self.class];
    NSString* path = [bundle pathForResource:@"OTMBeaconServices.plist" ofType:nil];
    
    [BLKService registerServicesDescriptorAtPath:path];
    
    path = [bundle pathForResource:@"OTMBeaconPortTypes.plist" ofType:nil];
    [BLKPort registerPortDescriptorAtPath:path];

    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings* settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeSound | UIUserNotificationTypeBadge
                                                                                 categories:nil];
        [application registerUserNotificationSettings:settings];
    }

    self.model = [OTMDataModel deserializedModel];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kISNotesManagerReadyNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification* note) {
                                                      // Just to ensure it's not another notes manager
                                                      if (note.object == self.notesManager) {
                                                          [application registerForRemoteNotifications];
                                                      }
                                                  }];

    self.notesManager = [ISNotesManager new];
    
    //start a background sound
    NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:@"pop" ofType: @"mp3"];
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:soundFilePath];
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
    self.audioPlayer.numberOfLoops = 1; //infinite loop

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    ISLogInfo(@"registered user notification settings");
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    // notify the server
    [self.notesManager updatePushNotificationsDeviceToken:deviceToken
                                          completionBlock:^(NSError *error) {
                                              if (error) {
                                                  ISLogError(@"Could not send device token to server: %@", error);
                                              } else {
                                                  ISLogInfo(@"Sent APNS token: %@", deviceToken);
                                              }
                                          }];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    ISLogError(@"Could not register for remote notifications: %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    ISLogInfo(@"received notification %@", userInfo);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kOTMPushNotification"
                                                        object:nil
                                                      userInfo:userInfo];
    
    [self.audioPlayer play];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    ISLogInfo(@"received notification with completion handler %@", userInfo);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kOTMPushNotification"
                                                        object:nil
                                                      userInfo:userInfo];
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive ||
        [UIApplication sharedApplication].applicationState == UIApplicationStateInactive) {
        [self.audioPlayer play];
    }
    
    completionHandler(UIBackgroundFetchResultNewData); // TODO:
}

@end
