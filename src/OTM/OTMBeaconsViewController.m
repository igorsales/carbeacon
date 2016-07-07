//
//  OTMBeaconsViewController.m
//  CarBeacon
//
//  Created by Igor Sales on 2015-10-28.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import "OTMBeaconsViewController.h"
#import "OTMBeaconIdentificationPort.h"
#import "OTMBeaconsViewCell.h"
#import "OTMProximityView.h"
#import "OTMBeaconLedger.h"

#import "OTMBeaconConfiguration.h"
#import "OTMBeaconConfigurationViewController.h"

#import "NSString+UUIDColour.h"
#import "NSTimer+Shortcut.h"

#import <BLEKit/BLEKit.h>

#define IS_LOG_LEVEL IS_LOG_LEVEL_DEBUG
#import "ISLog.h"


@interface _OTMBeaconDevice : NSObject

@property (nonatomic, copy)   NSString*    beaconUUID;
@property (nonatomic, strong) BLKDevice* device;
@property (nonatomic, assign) BOOL         hasBeenSeen;

@end

@implementation _OTMBeaconDevice

@end


@interface OTMBeaconsViewController () <BLKDiscoveryOperationDelegate, BLKDeviceConnection, UITextFieldDelegate>

@property (nonatomic, strong) BLKManager* manager;
@property (nonatomic, strong) BLKDiscoveryOperation* discoveryOperation;
@property (nonatomic, strong) NSMutableArray* beaconDevices;
@property (nonatomic, strong) NSMutableArray* discoveringDevices;

@property (nonatomic, weak)   NSTimer*        signalStrengthTimer;

@property (nonatomic, assign) BOOL isShowingConfiguration;

@end

@implementation OTMBeaconsViewController

#pragma mark - Setup/teardown

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self setup];
    }

    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self setup];
    }
    
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    if (self = [super initWithStyle:style]) {
        [self setup];
    }

    return self;
}

- (void)dealloc
{
    [self teardown];
}

- (void)setup
{
    if (!self.beacons) {
        self.beaconDevices = [NSMutableArray new];
    }

    if (!self.discoveringDevices) {
        self.discoveringDevices = [NSMutableArray new];
    }
}

- (void)teardown
{
    [self.discoveryOperation stop];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self populateBeaconDevices];

    self.manager = [BLKManager new];
    [self startDiscoveringCarBeacons];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.signalStrengthTimer = [NSTimer scheduledTimerWithTimeInterval:2.3
                                                                target:self
                                                              selector:@selector(signalStrengthTimerFired:)
                                                              userInfo:nil
                                                               repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self.signalStrengthTimer invalidate];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"carBeaconConfiguration"]) {
        UINavigationController* navCtrler = segue.destinationViewController;
        OTMBeaconConfigurationViewController* vc = (OTMBeaconConfigurationViewController*)navCtrler.topViewController;
        
        vc.device  = sender;
        vc.manager = self.manager;
    }
}

#pragma mark - Private

- (void)signalStrengthTimerFired:(NSTimer*)timer
{
    [self updateSignalStrengthIndicators];
}

- (void)updateSignalStrengthIndicators
{
    [self.tableView.visibleCells enumerateObjectsUsingBlock:^(OTMBeaconsViewCell* cell, NSUInteger idx, BOOL* stop) {
        _OTMBeaconDevice* bd = [self.beaconDevices objectAtIndex:idx];
        
        [self updateSignalStrengthIndicatorOnCell:(OTMBeaconsViewCell*)cell withBeaconDevice:bd];
    }];
}

- (void)updateSignalStrengthIndicatorOnCell:(OTMBeaconsViewCell*)cell withBeaconDevice:(_OTMBeaconDevice*)bd;
{
    // for now, don't update them all the time
    
    if (bd.hasBeenSeen) {
        cell.proximityView.proximity = OTMProximityNear;
    } else {
        cell.proximityView.proximity = OTMProximityOutside;
    }
}

- (void)populateBeaconDevices
{
    [self.beaconDevices removeAllObjects];
    for (NSString* beaconUUID in [self.beacons beaconUUIDStrings]) {
        _OTMBeaconDevice* bd = [_OTMBeaconDevice new];
        bd.beaconUUID = beaconUUID;
        [self.beaconDevices addObject:bd];
    }
}

- (_OTMBeaconDevice*)beaconDeviceForUUIDString:(NSString*)UUIDString
{
    __block _OTMBeaconDevice* bd = nil;
    [self.beaconDevices enumerateObjectsUsingBlock:^(_OTMBeaconDevice* obj, NSUInteger idx, BOOL* stop) {
        if ([obj.beaconUUID isEqualToString:UUIDString]) {
            bd = obj;
            *stop = YES;
        }
    }];
    
    return bd;
}

- (void)startDiscoveringCarBeacons
{
    self.discoveryOperation = [[BLKDiscoveryOperation alloc] initWithManager:self.manager];
    self.discoveryOperation.delegate = self;
    self.discoveryOperation.advertisingUUIDs = nil;
    
    [self.discoveryOperation start];
}

- (OTMBeaconsViewCell*)cellForIndexPath:(NSIndexPath*)indexPath
{
    return [self.tableView cellForRowAtIndexPath:indexPath];
}

- (NSString*)beaconUUIDForIndexPath:(NSIndexPath*)indexPath
{
    _OTMBeaconDevice* bd = [self.beaconDevices objectAtIndex:indexPath.row];

    return bd.beaconUUID;
}

- (void)updatePlateFromCellAtIndexPath:(NSIndexPath*)indexPath
{
    OTMBeaconsViewCell* cell = [self cellForIndexPath:indexPath];
    
    NSString* beaconUUIDString = [self beaconUUIDForIndexPath:indexPath];
    
    NSMutableDictionary* opts = (NSMutableDictionary*)[self.beacons optionsForBeaconUUID:beaconUUIDString];
    if (![opts isKindOfClass:[NSMutableDictionary class]]) {
        opts = [opts mutableCopy];
    }
    
    opts[@"licensePlate"] = cell.licensePlateTextField.text;
    
    [self.beacons addBeaconUUID:beaconUUIDString
                    withOptions:opts];
}

- (void)updateButtonsOnCell:(OTMBeaconsViewCell*)cell on:(BOOL)on
{
    [cell.checkButton removeTarget:nil
                            action:nil
                  forControlEvents:UIControlEventAllTouchEvents];
    
    [cell.removeButton removeTarget:nil
                             action:nil
                   forControlEvents:UIControlEventAllTouchEvents];
    
    if (on) {
        // switch is on, so leave it highlighted, but looking disabled
        cell.checkButton.alpha = 1.0;
        cell.removeButton.alpha = 0.27;
        
        [cell.removeButton addTarget:self
                              action:@selector(removeButtonTapped:)
                    forControlEvents:UIControlEventTouchUpInside];
    } else {
        // switch is off, so leave it highlighted, but looking disabled
        cell.checkButton.alpha = 0.27;
        cell.removeButton.alpha = 1.0;
        
        [cell.checkButton addTarget:self
                             action:@selector(checkButtonTapped:)
                   forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)switchBeaconAtIndexPath:(NSIndexPath*)indexPath to:(BOOL)on
{
    NSString* beaconUUIDString = [self beaconUUIDForIndexPath:indexPath];
    OTMBeaconsViewCell* cell = [self cellForIndexPath:indexPath];

    if (on) {
        NSString* plate = cell.licensePlateTextField.text;
        if (!plate) {
            plate = @"";
        }
        
        [self.beacons addBeaconUUID:beaconUUIDString
                        withOptions:@{@"licensePlate": plate}];
    } else {
        _OTMBeaconDevice* bd = [self.beaconDevices objectAtIndex:indexPath.row];
        
        [self.beacons removeBeaconUUID:bd.beaconUUID];
    }
    
    [self updateButtonsOnCell:cell on:on];
}

#pragma mark - Actions

- (IBAction)beaconSwitchValueChanged:(UISwitch*)sw
{
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:sw.tag inSection:0];

    [self switchBeaconAtIndexPath:indexPath to:sw.on];
}

- (IBAction)checkButtonTapped:(UIButton*)sender
{
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:sender.tag inSection:0];
    
    [self switchBeaconAtIndexPath:indexPath to:YES];
}

- (IBAction)removeButtonTapped:(UIButton*)sender
{
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:sender.tag inSection:0];
    
    [self switchBeaconAtIndexPath:indexPath to:NO];
}

- (IBAction)showCarBeaconConfiguration:(UIGestureRecognizer*)sender
{
    if (self.isShowingConfiguration) {
        return;
    }
    
    NSInteger index = sender.view.tag;
    ISLogDebug(@"User tapped to configure device at cell index: %@", @(index));
    
    if (index >= 0) {
        _OTMBeaconDevice* bd = self.beaconDevices[index];
        
        if (bd.device) {
            ISLogInfo(@"Showing config for device at index %@ (%@)", @(index), bd.beaconUUID);
            [self performSegueWithIdentifier:@"carBeaconConfiguration"
                                      sender:bd.device];
            self.isShowingConfiguration = YES;
        }
    }
}

- (IBAction)beaconConfigurationControllerDone:(UIStoryboardSegue*)segue
{
    self.isShowingConfiguration = NO;
}

- (IBAction)beaconConfigurationControllerCanceled:(UIStoryboardSegue*)segue
{
    self.isShowingConfiguration = NO;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.beaconDevices.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTMBeaconsViewCell* cell = nil;
    
    _OTMBeaconDevice* bd = [self.beaconDevices objectAtIndex:indexPath.row];
    
    cell = [tableView dequeueReusableCellWithIdentifier:@"beaconCell"
                                           forIndexPath:indexPath];
    
    NSString* beaconUUIDString = bd.beaconUUID;

    cell.paperView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Paper"]];
    cell.proximityView.tintColor = beaconUUIDString.UUIDColor;
    cell.beaconUUIDLabel.text    = [beaconUUIDString lowercaseString];
    cell.beaconSwitch.on         = [self.beacons.beaconUUIDStrings containsObject:beaconUUIDString];
    
    [cell.beaconSwitch removeTarget:nil
                             action:nil
                   forControlEvents:UIControlEventAllEvents];
    [cell.beaconSwitch addTarget:self
                          action:@selector(beaconSwitchValueChanged:)
                forControlEvents:UIControlEventValueChanged];
    cell.beaconSwitch.tag = cell.licensePlateTextField.tag = indexPath.row;
    
    cell.licensePlateTextField.delegate = self;
    cell.licensePlateTextField.text     = [self.beacons optionsForBeaconUUID:beaconUUIDString][@"licensePlate"];
    
    cell.tag = indexPath.row;
    cell.checkButton.tag = cell.removeButton.tag = indexPath.row;
    ISLogInfo(@"Setup cell for %@ with index %@", bd.beaconUUID, @(cell.tag));

    [cell.gestureRecognizers enumerateObjectsUsingBlock:^(UIGestureRecognizer* gr, NSUInteger idx, BOOL* stop) {
        [cell removeGestureRecognizer:gr];
    }];
    
    [self updateButtonsOnCell:cell on:[self.beacons.beaconUUIDStrings containsObject:beaconUUIDString]];
    
    UILongPressGestureRecognizer* lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                       action:@selector(showCarBeaconConfiguration:)];
    
    [cell addGestureRecognizer:lpgr];

    [self updateSignalStrengthIndicatorOnCell:cell withBeaconDevice:bd];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - BLKDiscoveryOperationDelegate

- (void)discoveryOperationDidUpdateDiscoveredPeripherals:(BLKDiscoveryOperation *)action
{
    ISLogInfo(@"discovered peripherals");
}

- (void)discoveryOperation:(BLKDiscoveryOperation *)operation didUpdateDevice:(BLKDevice *)device
{
    ISLogInfo(@"updated device: %@", device);
    
    OTMBeaconIdentificationPort* port = [device portOfType:kOTMBeaconPortTypeIdentification
                                                   atIndex:0
                                                  subIndex:0
                                               withOptions:nil];
    if (port) {
        if (![self.discoveringDevices containsObject:device]) {
            [self.discoveringDevices addObject:device];
            
            [self.manager attach:self toDevice:device];
        }
    }
}

#pragma mark - BLKDeviceConnection

- (void)deviceDidConnect:(BLKDevice *)device
{
    if ([self.discoveringDevices containsObject:device]) {
        OTMBeaconIdentificationPort* port = [device portOfType:kOTMBeaconPortTypeIdentification
                                                       atIndex:0
                                                      subIndex:0
                                                   withOptions:nil];

        [port read];
        
        [NSTimer after:0.5 do:^{
            [self.discoveringDevices removeObject:device];
            
            if (port.beaconUUID) {
                _OTMBeaconDevice* bd = [self beaconDeviceForUUIDString:port.beaconUUID.UUIDString];
                bd.hasBeenSeen = YES;
                
                BOOL reload = YES;
                NSIndexPath* indexPath = nil;
                if (!bd) {
                    bd = [_OTMBeaconDevice new];
                    bd.beaconUUID = port.beaconUUID.UUIDString;
                    [self.beaconDevices addObject:bd];
                    reload = NO;
                    indexPath = [NSIndexPath indexPathForRow:self.beaconDevices.count-1
                                                   inSection:0];
                } else {
                    indexPath = [NSIndexPath indexPathForRow:[self.beaconDevices indexOfObject:bd]
                                                   inSection:0];
                }
                
                bd.device = device;

                [self.manager detach:self fromDevice:device];
                
                [self.tableView beginUpdates];
                
                if (reload) {
                    [self.tableView reloadRowsAtIndexPaths:@[ indexPath ]
                                          withRowAnimation:UITableViewRowAnimationAutomatic];
                } else {
                    [self.tableView insertRowsAtIndexPaths:@[ indexPath ]
                                          withRowAnimation:UITableViewRowAnimationAutomatic];
                }
                
                [self.tableView endUpdates];
            }
        }];
    }
}

- (void)deviceDidDisconnect:(BLKDevice *)device
{
    
}

- (void)deviceAlreadyConnected:(BLKDevice *)device
{
    [self deviceDidConnect:device];
}

- (void)device:(BLKDevice *)device connectionFailedWithError:(NSError *)error
{
    
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];

    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:textField.tag inSection:0];
    [self updatePlateFromCellAtIndexPath:indexPath];
    
    return YES;
}

@end
