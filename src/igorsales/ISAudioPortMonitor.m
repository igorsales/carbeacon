//
//  ISAudioPortMonitor.m
//  BTConnTest
//
//  Created by Igor Sales on 2015-08-27.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import "ISAudioPortMonitor.h"
#import <AVFoundation/AVFoundation.h>

NSString* const ISAudioPortMonitorConnectivityChangedNotification = @"ISAudioPortMonitorConnectivityChangedNotification";

@interface ISAudioPortMonitor()

@property (nonatomic, assign) BOOL isConnectedToBluetoothPeripheral;

@end

@implementation ISAudioPortMonitor

#pragma mark - Setup/teardown

- (void)awakeFromNib
{
    // TODO: Fix this.
    [self setupAudioSession];
}

#pragma mark - Private

- (void)setupAudioSession
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(audioRouteChangedNotification:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:nil];

    AVAudioSession* session = [AVAudioSession sharedInstance];
    
    __autoreleasing NSError* error = nil;
    
    error = nil;
    if (![session setCategory:AVAudioSessionCategoryRecord
                  withOptions:AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionAllowBluetooth
                        error:&error] || error) {
        // TODO: Handle error condition
    }
    
    [session addObserver:self
              forKeyPath:@"currentRoute"
                 options:0
                 context:nil];
    
    [session addObserver:self
              forKeyPath:@"availableInputs"
                 options:0
                 context:nil];
}

- (void)teardownAudioSession
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:nil
                                                  object:nil];
}

- (void)audioRouteChangedNotification:(NSNotification*)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self examineChangesToRoute];
    });
}

- (void)examineChangesToRoute
{
    BOOL notify = NO;
    
    if ([self hasBluetoothInput] || [self hasBluetoothOutput]) {
        if (!self.isConnectedToBluetoothPeripheral) {
            notify = YES;
            self.isConnectedToBluetoothPeripheral = YES;
        }
    } else {
        if (self.isConnectedToBluetoothPeripheral) {
            notify = YES;
            self.isConnectedToBluetoothPeripheral = NO;
        }
    }
    
    if (notify) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ISAudioPortMonitorConnectivityChangedNotification
                                                            object:self];
    }
}

#pragma mark - Operations

- (NSArray*)discoveredPortNames
{
    AVAudioSession* session = [AVAudioSession sharedInstance];
    
    NSArray* ports = [session.availableInputs filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(AVAudioSessionPortDescription* pd,
                                                                                                                NSDictionary *bindings) {
        return ([pd.portType isEqualToString:AVAudioSessionPortBluetoothA2DP] ||
                [pd.portType isEqualToString:AVAudioSessionPortBluetoothHFP]);
    }]];
    
    NSArray* portNames = [ports valueForKey:@"portName"];
    
    return portNames;
}

- (BOOL)hasBluetoothInput
{
    AVAudioSession* session = [AVAudioSession sharedInstance];
    
    __block BOOL found = NO;
    [session.availableInputs enumerateObjectsUsingBlock:^(AVAudioSessionPortDescription* pd, NSUInteger idx, BOOL *stop) {
        if ([pd.portType isEqualToString:AVAudioSessionPortBluetoothHFP]) {
            *stop = found = YES;
        }
    }];
    
    return found;
}

- (BOOL)hasBluetoothOutput
{
    AVAudioSession* session = [AVAudioSession sharedInstance];
    
    __block BOOL found = NO;
    [session.availableInputs enumerateObjectsUsingBlock:^(AVAudioSessionPortDescription* pd, NSUInteger idx, BOOL *stop) {
        if ([pd.portType isEqualToString:AVAudioSessionPortBluetoothA2DP]) {
            *stop = found = YES;
        }
    }];
    
    return found;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self examineChangesToRoute];
}


@end
