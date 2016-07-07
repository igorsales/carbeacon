//
//  ISAudioPortMonitor.h
//  BTConnTest
//
//  Created by Igor Sales on 2015-08-27.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const ISAudioPortMonitorConnectivityChangedNotification;

@interface ISAudioPortMonitor : NSObject

@property (nonatomic, readonly) BOOL isConnectedToBluetoothPeripheral;

@property (nonatomic, readonly) NSArray* discoveredPortNames;
@property (nonatomic, strong)   NSArray* monitoredPortNames;

@end
