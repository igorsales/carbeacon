//
//  OTMBeaconConfigurationViewController.m
//  OCTM
//
//  Created by Igor Sales on 2015-09-22.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import "OTMBeaconConfigurationViewController.h"
#import "OTMBeaconConfigurationSliderCell.h"
#import "OTMBeaconConfigurationReadingCell.h"
#import "OTMBeaconConfigurationPort.h"
#import "OTMBeaconIdentificationPort.h"
#import "OTMRSSICalibrationAlgorithm.h"

#import "OTMBeaconConfiguration.h"

#import "NSTimer+Shortcut.h"

#import "ISLog.h"

#import <BLEKit/BLEKit.h>

#define kOTMBeaconConfigurationADCCoefficientTo13V ((3.3 * 5.2) / 32768.0)
#define kOTMBeaconConfigurationADCCoefficientTo1ms (1.0/32000.0 * 1000.0)

@interface OTMBeaconConfigurationViewController () <BLKDeviceConnection, OTMRSSICalibrationAlgorithmDelegate>

@property (nonatomic, assign) BOOL connected;
@property (nonatomic, weak) NSTimer* ADCReadoutTimer;

@property (nonatomic, strong) NSUUID* beaconUUID;
@property (nonatomic, assign) uint16_t major;
@property (nonatomic, assign) uint16_t minor;
@property (nonatomic, assign) int8_t   measuredRSSI;

@property (nonatomic, weak)   UIProgressView* progressView;

@property (nonatomic, strong) OTMRSSICalibrationAlgorithm* calibration;

@end

@implementation OTMBeaconConfigurationViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.configuration = [OTMBeaconConfiguration new];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.manager attach:self toDevice:self.device];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self stopReadingADC];

    [self.manager detach:self fromDevice:self.device];

    OTMBeaconConfigurationReadingCell* cell = (OTMBeaconConfigurationReadingCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
    
    cell.target = nil;
    cell.keyPath = nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"done"]) {
        [self applyConfiguration:self.configuration toDevice:self.device];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0: return self.connected ? 6 : 0;
        case 1: return 1;
        case 2: return 1;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        static NSArray* specs = nil;
        if (!specs) {
            specs = @[
                      @{
                          @"label": @"Threshold ON",
                          @"step": @(0.1),
                          @"unit": @"V",
                          @"keyPath": @"configuration.thresholdON",
                          @"min": @(0), @"max": @(16)
                        },
                      @{
                          @"label": @"Threshold FULL",
                          @"step": @(0.1),
                          @"unit": @"V",
                          @"keyPath": @"configuration.thresholdFULL",
                          @"min": @(0), @"max": @(16)
                          },
                      @{
                          @"label": @"Threshold CRANK",
                          @"step": @(0.1),
                          @"unit": @"V",
                          @"keyPath": @"configuration.thresholdCRANK",
                          @"min": @(0), @"max": @(16)
                          },
                      @{
                          @"label": @"State Change Timeout",
                          @"step": @(1),
                          @"unit": @"ms",
                          @"keyPath": @"configuration.stateChangeTimeout",
                          @"min": @(0), @"max": @(5000)
                          },
                      @{
                          @"label": @"Beacon ON/OFF Timeout",
                          @"step": @(1),
                          @"unit": @"ms",
                          @"keyPath": @"configuration.onOffTimeout",
                          @"min": @(0), @"max": @(5000)
                          },
                      @{
                          @"label": @"ADC Timeout",
                          @"step": @(1),
                          @"unit": @"ms",
                          @"keyPath": @"configuration.ADCTimeout",
                          @"min": @(0), @"max": @(5000)
                          },
                      ];
        }
        
        OTMBeaconConfigurationSliderCell* cell = [tableView dequeueReusableCellWithIdentifier:@"sliderSettingCell"
                                                                                 forIndexPath:indexPath];
        
        NSDictionary* spec = specs[indexPath.row];
        cell.label.text = spec[@"label"];
        cell.unitLabel.text = spec[@"unit"];
        cell.plusOrMinusStep = [spec[@"step"] doubleValue];
        cell.slider.minimumValue = [spec[@"min"] doubleValue];
        cell.slider.maximumValue = [spec[@"max"] doubleValue];
        cell.target = self;
        cell.keyPath = spec[@"keyPath"];

        return cell;
    } else if (indexPath.section == 1) {
        OTMBeaconConfigurationReadingCell* cell = [tableView dequeueReusableCellWithIdentifier:@"currentReadingCell"
                                                                                  forIndexPath:indexPath];
        
        cell.target = self;
        cell.keyPath = @"configuration.currentReading";
        
        return cell;
    } else if (indexPath.section == 2) {
        OTMBeaconConfigurationReadingCell* cell = [tableView dequeueReusableCellWithIdentifier:@"beaconUUIDCell"
                                                                                  forIndexPath:indexPath];
        
        NSString* string = [NSString stringWithFormat:@"%@\n(%@,%@)\tMeasured RSSI: %@",
                            self.beaconUUID.UUIDString.lowercaseString,
                            @(self.major),
                            @(self.minor),
                            @(self.measuredRSSI)];
        cell.label.text = string;
        cell.target = self;
        
        self.progressView = cell.progressView;
        
        return cell;
    }
    
    return nil;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 2) {
        return YES;
    }

    return NO;
}

- (NSArray*)tableView:(UITableView*)tableView editActionsForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (indexPath.section == 2) {
        UITableViewRowAction* action1 = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive
                                                                           title:NSLocalizedString(@"Randomize", nil) handler:^(UITableViewRowAction* action, NSIndexPath* indexPath) {
                                                                               [self applyRandomBeaconUUID];
                                                                           }];
        
        UITableViewRowAction* action2 = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                                                           title:NSLocalizedString(@"Calibrate", nil) handler:^(UITableViewRowAction* action, NSIndexPath* indexPath) {
                                                                               [self startBeaconCalibration];
                                                                           }];
        return @[ action1, action2 ];
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0: return NSLocalizedString(@"Configuration", nil);
        case 1: return NSLocalizedString(@"Readings", nil);
        case 2: return NSLocalizedString(@"Beacon UUID", nil);
            
        default: return nil;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - BLKDeviceConnection

- (void)device:(BLKDevice *)device connectionFailedWithError:(NSError *)error
{
    [self stopReadingADC];
}

- (void)deviceAlreadyConnected:(BLKDevice *)device
{
    [self deviceDidConnect:device];
}

- (void)deviceDidConnect:(BLKDevice *)device
{
    if (!self.connected) {
        self.connected = YES;

        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:@[
                                                 [NSIndexPath indexPathForRow:0 inSection:0],
                                                 [NSIndexPath indexPathForRow:1 inSection:0],
                                                 [NSIndexPath indexPathForRow:2 inSection:0],
                                                 [NSIndexPath indexPathForRow:3 inSection:0],
                                                 [NSIndexPath indexPathForRow:4 inSection:0],
                                                 [NSIndexPath indexPathForRow:5 inSection:0],
                                                 ]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }

    [self readConfigurationFromDevice:device];
    [self startReadingADC];
    [self readBeaconUUID];
}

- (void)deviceDidDisconnect:(BLKDevice *)device
{
    [self stopReadingADC];
    [self.calibration stop];
    self.calibration = nil;
}

#pragma mark - Private

- (void)reloadConfiguration
{
    for (NSInteger idx = 0; idx < [self tableView:self.tableView numberOfRowsInSection:0]; idx++) {
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
        OTMBeaconConfigurationSliderCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
        
        [cell reload];
    }
}

- (void)readConfiguration:(OTMBeaconConfiguration*)cfg fromDevice:(BLKDevice*)device
{
    OTMBeaconConfigurationPort* port = [device portOfType:kOTMBeaconPortTypeConfiguration
                                             atIndex:0
                                            subIndex:0
                                         withOptions:nil];
    
    CGFloat mult = (3.3 * 5.2) / 32768.0;
    cfg.thresholdON    = mult * port.thresholdOn;
    cfg.thresholdFULL  = mult * port.thresholdFull;
    cfg.thresholdCRANK = mult * port.thresholdCrank;
    
    mult = 1.0/32000.0 * 1000.0; // in ms
    cfg.stateChangeTimeout = mult * port.stateChangeTimeout;
    cfg.onOffTimeout       = mult * port.onOffTimeout;
    cfg.ADCTimeout         = mult * port.ADCTimeout;
}

- (void)applyConfiguration:(OTMBeaconConfiguration*)cfg toDevice:(BLKDevice*)device
{
    OTMBeaconConfigurationPort* port = [device portOfType:kOTMBeaconPortTypeConfiguration
                                                  atIndex:0
                                                 subIndex:0
                                              withOptions:nil];
    
    CGFloat mult = kOTMBeaconConfigurationADCCoefficientTo13V;
    port.thresholdOn    = cfg.thresholdON / mult;
    port.thresholdFull  = cfg.thresholdFULL / mult;
    port.thresholdCrank = cfg.thresholdCRANK / mult;
    
    mult = kOTMBeaconConfigurationADCCoefficientTo1ms; // in ms
    port.stateChangeTimeout = cfg.stateChangeTimeout / mult;
    port.onOffTimeout       = cfg.onOffTimeout / mult;
    port.ADCTimeout         = cfg.ADCTimeout / mult;
    
    [port commit];
}

- (void)readConfigurationFromDevice:(BLKDevice*)device
{
    OTMBeaconConfigurationPort* port = [device portOfType:kOTMBeaconPortTypeConfiguration
                                                  atIndex:0
                                                 subIndex:0
                                              withOptions:nil];
    [port read];
    
    [NSTimer after:0.5 do:^{
        [self readConfiguration:self.configuration fromDevice:self.device];
        [self reloadConfiguration];
    }];
}

- (void)readADCValueFromDevice:(BLKDevice*)device intoConfiguration:(OTMBeaconConfiguration*)cfg
{
    BLKADCPort* port = [device portOfType:kBLKPortTypeADCs
                                    atIndex:0
                                   subIndex:0
                                withOptions:nil];
    
    cfg.currentReading = kOTMBeaconConfigurationADCCoefficientTo13V * [port readingForPin:0];
}

- (void)readADCReadingFromDevice:(BLKDevice*)device
{
    BLKADCPort* port = [device portOfType:kBLKPortTypeADCs
                                    atIndex:0
                                   subIndex:0
                                withOptions:nil];
    [port read];
    [NSTimer after:0.5 do:^{
        [self readADCValueFromDevice:device intoConfiguration:self.configuration];
    }];
}

- (void)startReadingADC
{
    [self stopReadingADC];
    self.ADCReadoutTimer = [NSTimer scheduledTimerWithTimeInterval:0.25
                                                            target:self
                                                          selector:@selector(ADCTimerFired:)
                                                          userInfo:nil
                                                           repeats:YES];
}

- (void)stopReadingADC
{
    [self.ADCReadoutTimer invalidate];
}

- (void)ADCTimerFired:(NSTimer*)timer
{
    [self readADCValueFromDevice:self.device
               intoConfiguration:self.configuration];

    BLKADCPort* port = [self.device portOfType:kBLKPortTypeADCs
                                         atIndex:0
                                        subIndex:0
                                     withOptions:nil];

    [port read];
}

- (void)updateBeaconUUIDCell
{
    OTMBeaconIdentificationPort* port = [self.device portOfType:kOTMBeaconPortTypeIdentification
                                                        atIndex:0
                                                       subIndex:0
                                                    withOptions:nil];
    self.beaconUUID   = port.beaconUUID;
    self.major        = port.major;
    self.minor        = port.minor;
    self.measuredRSSI = port.measuredRSSI;

    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:0 inSection:2] ]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
}

- (void)readBeaconUUID
{
    OTMBeaconIdentificationPort* port = [self.device portOfType:kOTMBeaconPortTypeIdentification
                                                        atIndex:0
                                                       subIndex:0
                                                    withOptions:nil];
    
    [port read];
    
    [NSTimer after:0.5 do:^{
        [self updateBeaconUUIDCell];
    }];
}

- (void)applyRandomBeaconUUID
{
    OTMBeaconIdentificationPort* port = [self.device portOfType:kOTMBeaconPortTypeIdentification
                                                        atIndex:0
                                                       subIndex:0
                                                    withOptions:nil];
    
    self.beaconUUID = [NSUUID UUID];

    [port writeBeaconUUID:self.beaconUUID major:port.major minor:port.minor measuredRSSI:port.measuredRSSI];
    
    [NSTimer after:0.5 do:^{
        [self updateBeaconUUIDCell];
    }];
    
    [self.tableView setEditing:NO animated:YES];
}

#pragma mark - Calibration algorithm

- (void)startBeaconCalibration
{
    self.calibration          = [OTMRSSICalibrationAlgorithm new];
    self.calibration.device   = self.device;
    self.calibration.delegate = self;
    
    [self.calibration start];
}

- (void)calibrationAlgorithmDidStart:(OTMRSSICalibrationAlgorithm *)algo
{
    [self.tableView setEditing:NO animated:YES];
    self.progressView.hidden = NO;
}

- (void)calibrationAlgorithm:(OTMRSSICalibrationAlgorithm *)algo didProgressTo:(double)progress
{
    [self.progressView setProgress:progress animated:YES];
}

- (void)calibrationAlgorithm:(OTMRSSICalibrationAlgorithm *)algo didFinishWithMeasuredRSSI:(int8_t)measuredRSSI
{
    self.measuredRSSI        = algo.measuredRSSI;
    self.progressView.hidden = YES;
    self.calibration         = nil;
    
    OTMBeaconIdentificationPort* port = [self.device portOfType:kOTMBeaconPortTypeIdentification
                                                        atIndex:0
                                                       subIndex:0
                                                    withOptions:nil];
    
    [port writeBeaconUUID:port.beaconUUID major:port.major minor:port.minor measuredRSSI:self.measuredRSSI];
    
    [NSTimer after:0.5 do:^{
        [self updateBeaconUUIDCell];
    }];
}

- (void)calibrationAlgorithmDidFail:(OTMRSSICalibrationAlgorithm *)algo
{
    self.progressView.hidden = YES;
    
    // TODO: Better handle this case
    
    self.calibration = nil;
}

@end
