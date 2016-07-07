//
//  ViewController.m
//  BTConnTest
//
//  Created by Igor Sales on 2015-08-26.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import "OTMMapViewController.h"
#import "ISBTSourcePickerViewController.h"
#import "OTMBeaconConfigurationPort.h"
#import "OTMLocationMonitor.h"
#import "OTMConnectViewController.h"
#import "ISNotesManager.h"
#import "AppDelegate.h"
#import "OTMLocationManager.h"
#import "OTMConstants.h"
#import "NSString+UUIDColour.h"
#import "OTMCalendarPinAnnotationView.h"
#import "ISDisclosureButton.h"
#import "OTMDateAndTimeViewController.h"
#import "OTMLocationObservation.h"
#import "OTMDataModel.h"
#import "OTMLocationDatabase.h"
#import "OTMMapAnnotation.h"
#import "OTMPeerSharingLedger.h"
#import "UIView+OTMDateAndTimeFormatter.h"
#import "OTMSourcePickerController.h"
#import "OTMCarPinAnnotationView.h"
#import "UIImage+Tint.h"
#import "OTMBeaconsViewController.h"
#import "OTMBeaconLedger.h"
#import "OTMBeaconsListController.h"

#import "NSArray+CollectSelect.h"

#import <ExternalAccessory/ExternalAccessory.h>
#import <AVFoundation/AVFoundation.h>

#define _USE_BLEKIT_

#ifdef _USE_BLEKIT_
#import <BLEKit/BLEKit.h>
#endif

#import <BLEKit/UINib+NibView.h>


#define IS_LOG_LEVEL IS_LOG_LEVEL_INFO
#import "ISLog.h"

@interface OTMMapViewController () <UITextViewDelegate,
                                    OTMDateAndTimePickerProtocol,
                                    OTMSourcePickerControllerDelegate,
                                    OTMLocationManagerDelegate,
                                    MKMapViewDelegate>

@property (nonatomic, weak)   NSTimer* ADCTimer;

@property (nonatomic, weak)   OTMDateAndTimeViewController* dateAndTimeViewController;
@property (nonatomic, weak)   OTMSourcePickerController*    sourcePickerController;

@property (nonatomic, copy)   NSString* selectedPeer;
@property (nonatomic, copy)   NSArray*  selectedBeacons;

@property (nonatomic, assign) BOOL zoomedIntoUserOnce;

@property (nonatomic, strong) OTMMapAnnotation* lastAcquiredLocationAnnotation;
@property (nonatomic, strong) NSMutableSet*     beaconAnnotations;

@property (nonatomic, strong) NSDateFormatter*  dateFormatter;
@property (nonatomic, strong) NSDateFormatter*  timeFormatter;

@property (nonatomic, assign) BOOL isShowingBeaconLedger;

@end

@implementation OTMMapViewController

#pragma mark - Accessors

- (OTMDataModel*)model
{
    return ((AppDelegate*)([UIApplication sharedApplication].delegate)).model;
}

#pragma mark - Overrides

- (void)viewDidLoad
{
    [super viewDidLoad];

    AppDelegate* delegate = [UIApplication sharedApplication].delegate;
    self.notesManager = delegate.notesManager;
    
    if (self.locationMonitor.needsAuthorization) {
        [self.locationMonitor requestAuthorization:self];
    }

    self.locationMonitor.beaconUUIDStrings = self.model.beacons.beaconUUIDStrings;

    [self.locationMonitor startBeaconTracking:self];
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSData* locManagerData = [defaults dataForKey:@"kOTMLocationManager"];
    if (locManagerData) {
        self.locationManager = [NSKeyedUnarchiver unarchiveObjectWithData:locManagerData];
    }
    if (!self.locationManager) {
        self.locationManager = [[OTMLocationManager alloc] initWithSharingCategory:kOTMPeerSharingCategoryCarLocation];
    }
    self.locationManager.delegate = self;
    self.locationManager.notesManager = self.notesManager;
    self.model                        = ((AppDelegate*)([UIApplication sharedApplication].delegate)).model;
    self.locationManager.model        = self.model;
    [self.locationManager flush];

    self.beaconsController.beacons = self.model.beacons;
    [self addChildViewController:self.beaconsController];

    self.locationMonitor.delegate = self.locationManager;
    
    self.dateFormatter = [NSDateFormatter new];
    self.dateFormatter.dateFormat = @"MMM. d";

    self.timeFormatter = [NSDateFormatter new];
    self.timeFormatter.dateFormat = @"HH:mm";
    
    self.beaconAnnotations = [NSMutableSet new];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"kOTMPushNotification"
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification * _Nonnull note) {
                                                      ISLogDebug(@"Received push notification. Scheduling fetch");
                                                      [self fetch:self];
                                                  }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.beaconsController.beacons = self.model.beacons;
    if (self.model.beacons.beaconUUIDStrings.count == 0) {
        // need to get beacons first
        [self showBeaconsLedger:self];
    }
    
    [self pickLatestObservationFromCurrentSource];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Overrides

- (BOOL)shouldAutorotate
{
    if (self.sourcePickerController || self.dateAndTimeViewController) {
        return NO;
    }
    
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"connectWithPeers"]) {
        if (self.notesManager.ready) {
            UINavigationController* navCtrler = segue.destinationViewController;
            OTMConnectViewController* peerVC = (id)navCtrler.topViewController;
            peerVC.userId = self.notesManager.userId;
            peerVC.ledger = ((AppDelegate*)([UIApplication sharedApplication].delegate)).model.ledger;
            peerVC.notesManager = self.notesManager;
        } else {
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Uh-oh"
                                                                           message:@"Not yet ready"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Dismiss"
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:nil];
            
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
    } else if ([segue.identifier isEqualToString:@"beaconsLedger"]) {
        [self.locationMonitor stopBeaconTracking:self];
        UINavigationController* navCtrler = segue.destinationViewController;
        OTMBeaconsViewController* ctrler = (id)navCtrler.topViewController;
        ctrler.beacons = [self.model.beacons copy];
    }
}

#pragma mark - Actions

- (IBAction)eraseLocations:(id)sender
{
    [self.model.database removeObservationsFor:self.selectedPeer];
    [self.model serialize];
}

- (IBAction)applyChangesFromConnect:(UIStoryboardSegue *)segue
{
    OTMDataModel* model = self.model;
    
    OTMConnectViewController* peerCtrler = segue.sourceViewController;
    model.ledger = peerCtrler.ledger;
    
    [model serialize];
}

- (IBAction)cancelChangesFromConnect:(UIStoryboardSegue *)segue
{
}

- (IBAction)dismissCarBeaconSettings:(UIStoryboardSegue *)segue
{
    OTMBeaconsViewController* ctrler = segue.sourceViewController;

    self.model.beacons = ctrler.beacons;
    [self.model serialize];

    self.locationMonitor.beaconUUIDStrings = self.model.beacons.beaconUUIDStrings;
    self.beaconsController.beacons = self.model.beacons;

    [self.locationMonitor startBeaconTracking:self];
    
    self.isShowingBeaconLedger = NO;
}

- (IBAction)fetch:(id)sender
{
    [self.notesManager fetchAndDecryptIncomingMessagesWithCompletionBlock:^(NSArray *newMessages, NSError *error) {
        if (error) {
            NSLog(@"Error %@", error);
        } else {
            ISLogDebug(@"Messages: %@", newMessages);
            [self processPeerMessages:newMessages];
            [self.model serialize];
        }
    }];
}

- (IBAction)resetIdentity:(id)sender
{
    [self.notesManager resetIdentity];
}

- (IBAction)toggleObservationSourcePicker:(id)sender
{
    if (self.observationSourceDisclosureButton.arrowDirection == ISDisclosureDirectionUp) {
        [self showObservationSourcePicker:sender];
    } else {
        [self hideObservationSourcePicker:sender];
    }
}

- (IBAction)showObservationSourcePicker:(id)sender
{
    [self hideDateAndTimePicker:self];

    // user tapped to go up
    OTMSourcePickerController* ctrler = [self.storyboard instantiateViewControllerWithIdentifier:@"SourcePicker"];
    
    ctrler.ownSources = @[
                          [OTMSourcePickerController sourceWithTitle:[UIDevice currentDevice].name
                                                            subtitle:self.notesManager.userId],
                          ];
    
    // piggyback to determine the current source
    ctrler.selectedSource = ctrler.ownSources[0];

    ctrler.peerSources = [[self.model.ledger usersAllowedToReceive:kOTMPeerSharingCategoryCarLocation]
                          collect:^id(NSString* peer) {
                              NSDictionary* user = [self.model.ledger optionsToReceive:kOTMPeerSharingCategoryCarLocation
                                                                               forUser:peer];
                              id<OTMSource> src = [OTMSourcePickerController sourceWithTitle:user[@"name"]
                                                                                    subtitle:peer];
                              
                              // piggyback to determine the current source
                              if ([self.selectedPeer isEqualToString:peer]) {
                                  ctrler.selectedSource = src;
                              }
                              
                              src.referenceObject = peer;
                              
                              return src;
                          }];
    
    if (!ctrler.peerSources) {
        ctrler.peerSources = @[];
    }
    
    ctrler.peerSources = [ctrler.peerSources arrayByAddingObject:
                          [OTMSourcePickerController sourceWithTitle:NSLocalizedString(@"Configure...", nil)]
                          ];
    
    ctrler.beacons = [self.model.beacons.beaconUUIDStrings collect:^id(NSString* beaconUUIDString) {
        NSDictionary* beaconOpts = [self.model.beacons optionsForBeaconUUID:beaconUUIDString];
        
        id<OTMSource> src = [OTMSourcePickerController sourceWithTitle:[beaconOpts[@"licensePlate"] uppercaseString]
                                                              subtitle:beaconUUIDString];
        
        src.referenceObject = @[ beaconUUIDString ];
        
        // piggyback to determine the current source
        if ([self.selectedBeacons containsObject:beaconUUIDString]) {
            ctrler.selectedSource = src;
        }
        
        return src;
    }];
    
    id<OTMSource> source = [OTMSourcePickerController sourceWithTitle:NSLocalizedString(@"All", nil)];
    
    source.referenceObject = self.model.beacons.beaconUUIDStrings;
    
    ctrler.beacons = [@[source] arrayByAddingObjectsFromArray:ctrler.beacons];
    
    ctrler.beacons = [ctrler.beacons arrayByAddingObject:
                      [OTMSourcePickerController sourceWithTitle:NSLocalizedString(@"Configure...", nil)]
                      ];
    
    ctrler.delegate = self;
    
    [ctrler slideFromBottomOntoViewController:self shiftView:self.contentView];
    self.sourcePickerController = ctrler;
    
    [self.observationSourceDisclosureButton setDisclosureDirection:ISDisclosureDirectionDown
                                                          animated:YES];
}

- (IBAction)hideObservationSourcePicker:(id)sender
{
    [self.sourcePickerController slideOutShiftingViewBack:self.contentView];
    self.sourcePickerController = nil;

    [self.observationSourceDisclosureButton setDisclosureDirection:ISDisclosureDirectionUp
                                                          animated:YES];
}

- (IBAction)showDateAndTimePicker:(id)sender
{
    [self hideObservationSourcePicker:sender];

    OTMDateAndTimeViewController* ctrler = [self.storyboard instantiateViewControllerWithIdentifier:@"DateAndTime"];
    
    ctrler.dataSource = [self selectedObservationSource];

    ctrler.delegate = self;
    
    [ctrler slideFromRightOntoViewController:self view:self.contentView];
    self.dateAndTimeViewController = ctrler;
}

- (IBAction)hideDateAndTimePicker:(id)sender
{
    [self.dateAndTimeViewController slideOut];
    self.dateAndTimeViewController = nil;
}

- (IBAction)toggleDateAndTimePicker:(id)sender
{
    if (self.dateAndTimeViewController) {
        [self hideDateAndTimePicker:sender];
    } else {
        [self showDateAndTimePicker:sender];
    }
}

- (IBAction)showBeaconsLedger:(id)sender
{
    self.isShowingBeaconLedger = NO;

    [self performSegueWithIdentifier:@"beaconsLedger" sender:sender];
}

- (IBAction)showTasks:(id)sender
{
    [self hideDateAndTimePicker:self];
    [self hideObservationSourcePicker:self];

    UIAlertController* alertCtrler = [UIAlertController alertControllerWithTitle:nil
                                                                         message:NSLocalizedString(@"Actions", nil)
                                                                  preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alertCtrler addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Fetch", nil)
                                                    style:UIAlertActionStyleDefault
                                                  handler:^(UIAlertAction* action) {
                                                      [self fetch:self];
                                                  }]];
    
    [alertCtrler addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Acquire Location", nil)
                                                    style:UIAlertActionStyleDefault
                                                  handler:^(UIAlertAction*  action) {
                                                      [self.locationMonitor acquireLocation:self];
                                                  }]];
    
    [alertCtrler addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Erase locations", nil)
                                                    style:UIAlertActionStyleDestructive
                                                   handler:^(UIAlertAction*  action) {
                                                       [self eraseLocations:self];
                                                   }]];
    
    [alertCtrler addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Reset Identity", nil)
                                                    style:UIAlertActionStyleDestructive
                                                  handler:^(UIAlertAction * _Nonnull action) {
                                                      [self resetIdentity:self];
                                                  }]];
    
    [alertCtrler addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                    style:UIAlertActionStyleCancel
                                                  handler:^(UIAlertAction * _Nonnull action) {
                                                      [alertCtrler dismissViewControllerAnimated:YES completion:nil];
                                                  }]];
    
    [self presentViewController:alertCtrler
                       animated:YES
                     completion:^{
                         
                     }];
}

- (IBAction)showConnectWithPeers:(id)sender
{
    [self performSegueWithIdentifier:@"connectWithPeers"
                              sender:self];
}

#pragma mark - Private

- (id)selectedObservationSource
{
    if (self.selectedPeer) {
        return [self.model.database dataSourceForObservationsFromPeer:self.selectedPeer];
    } else if (self.selectedBeacons.count) {
        return [self.model.database dataSourceForObservationsFromBeaconUUIDStrings:self.selectedBeacons];
    } else {
        return [self.model.database dataSourceForOwnObservations];
    }
}

- (void)pickLatestObservationFromCurrentSource
{
    id<OTMObservationDataSource> dataSource = [self selectedObservationSource];

    OTMLocationObservation* obs = dataSource.allObservations.firstObject;
    if (obs) {
        [self focusOnObservation:obs selected:YES];
    }
}

- (void)clearAnnotations
{
    [self.mapView removeAnnotations:self.beaconAnnotations.allObjects];
    
    if (self.lastAcquiredLocationAnnotation) {
        [self.mapView removeAnnotation:self.lastAcquiredLocationAnnotation];
        self.lastAcquiredLocationAnnotation = nil;
    }
}

- (void)focusOnObservation:(OTMLocationObservation*)obs selected:(BOOL)selected
{
    [self clearAnnotations];
    
    OTMMapAnnotation* annotation = [self annotationWithOnbservation:obs];
    
    [self.beaconAnnotations addObject:annotation];
    [self.mapView addAnnotation:annotation];
    
    // zoom in to current markers
    [self.locationMonitor encircleMarkers];
    
    if (selected) {
        [self.mapView selectAnnotation:annotation animated:YES];
    }
}

- (void)processPeerMessages:(NSArray*)messages
{
    // first sort from oldest to newest
    @try {
        messages = [messages sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"when"
                                                                                         ascending:YES]]];
    }
    @catch (NSException *exception) {
        ISLogError(@"Could not sort messages by 'when'");
    }
    
    __block BOOL foundMessages = NO;
    [messages enumerateObjectsUsingBlock:^(NSDictionary* dict, NSUInteger idx, BOOL * stop) {
        if (![dict isKindOfClass:[NSDictionary class]]) {
            return;
        }

        NSString* from = dict[@"from"];
        NSString* what = dict[@"what"];
        NSString* when = dict[@"when"];
        
        if (![what isKindOfClass:[NSString class]]) {
            return;
        }
        
        NSData* JSONData = [what dataUsingEncoding:NSUTF8StringEncoding];
        OTMLocationObservation* observation = [[OTMLocationObservation alloc] initWithJSONData:JSONData
                                                                                          from:from];
        

        if (!observation) {
            ISLogInfo(@"Message from %@ on %@ could not be understood", from, when);
            return;
        }

        [self.model.database addObservation:observation];
        
        foundMessages = YES;
    }];

    if (!foundMessages) {
        ISLogInfo(@"No messages found for me.");
    }
}

- (OTMMapAnnotation*)annotationWithOnbservation:(OTMLocationObservation*)observation
{
    OTMMapAnnotation* annotation = [[OTMMapAnnotation alloc] initWithObservation:observation];
    annotation.title    = [self.dateFormatter stringFromDate:observation.location.timestamp];
    annotation.subtitle = [self.timeFormatter stringFromDate:observation.location.timestamp];
    
    return annotation;
}

- (void)prepareCarAnnotations
{
    [self clearAnnotations];

    [self.model.beacons.beaconUUIDStrings enumerateObjectsUsingBlock:^(NSString* beaconUUIDString, NSUInteger idx, BOOL* stop) {
        OTMLocationObservation* observation = [self.model.database latestObservationForBeaconUUIDString:beaconUUIDString];
        if (observation) {
            OTMMapAnnotation* annotation = [self annotationWithOnbservation:observation];
            [self.beaconAnnotations addObject:annotation];
        }
    }];

    [self.mapView addAnnotations:self.beaconAnnotations.allObjects];
}

#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if (!self.zoomedIntoUserOnce) {
        self.zoomedIntoUserOnce = YES;
        [self.locationMonitor encircleMarkers];
    }
}

- (MKAnnotationView*)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    
    OTMMapAnnotation* carAnnotation = nil;
    
    if (annotation == self.lastAcquiredLocationAnnotation) {
        carAnnotation = annotation;
    } else if ([self.beaconAnnotations containsObject:annotation]) {
        carAnnotation = annotation;
    }
    
    if (carAnnotation) {
        OTMCarPinAnnotationView* pinView = (OTMCarPinAnnotationView*)[UINib viewFromNibNamed:@"CarPin"
                                                                                      bundle:nil];
        
        UIColor* tint = nil;
        pinView.licensePlateView.hidden = YES;
        if (carAnnotation.observation.beaconUUIDString) {
            tint = carAnnotation.observation.fromUserId.UUIDColor;
            if (!tint) {
                // When the fromUserId is empty, it means it came from us
                tint = self.notesManager.userId.UUIDColor;
            }

            NSDictionary* options = nil;
            if ((options = [self.model.beacons optionsForBeaconUUID:carAnnotation.observation.beaconUUIDString])) {
                NSString* plate = options[@"licensePlate"];
                if (plate) {
                    pinView.licensePlateLabel.text = plate;
                    pinView.licensePlateView.hidden = NO;
                }
            }
            
            CGFloat acc = MAX(carAnnotation.observation.location.horizontalAccuracy,
                              carAnnotation.observation.location.verticalAccuracy);

            [pinView setAccuracy:acc onMapView:self.mapView animated:NO];
        } else {
            // Fallback to user's user id colour
            tint = self.notesManager.userId.UUIDColor;
        }
        
        pinView.carBodyImageView.image = [pinView.carBodyImageView.image
                                          imageTintedWithColor:tint];
        
        
        pinView.annotation     = annotation;
        pinView.canShowCallout = NO;
        
        return pinView;
    }
    
    if ([annotation isKindOfClass:[OTMMapAnnotation class]]) {
        OTMCalendarPinAnnotationView* pinView = (OTMCalendarPinAnnotationView*)[UINib viewFromNibNamed:@"CalendarWithTimePin" bundle:nil];
        pinView.annotation = annotation;
        
        OTMMapAnnotation* mapAnnotation = (OTMMapAnnotation*)annotation;
        [pinView formatWithDate:mapAnnotation.observation.location.timestamp];
        
        return pinView;
    }

    MKAnnotationView* view = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:nil];

    view.image = [UIImage imageNamed:@"CarIcon"];
    
    return view;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    // trap here to dismiss the auxiliary VC's
    [self hideDateAndTimePicker:self];
    [self hideObservationSourcePicker:self];
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    // trap here to dismiss the auxiliary VC's
    [self hideDateAndTimePicker:self];
    [self hideObservationSourcePicker:self];
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    [mapView.annotations enumerateObjectsUsingBlock:^(OTMMapAnnotation* ann, NSUInteger idx, BOOL* stop) {
        OTMCarPinAnnotationView* view = (OTMCarPinAnnotationView*)[mapView viewForAnnotation:ann];
        
        if ([view isKindOfClass:[OTMCarPinAnnotationView class]]) {
            CGFloat acc = MAX(ann.observation.location.horizontalAccuracy,
                              ann.observation.location.verticalAccuracy);
            
            [view setAccuracy:acc onMapView:mapView animated:animated];
        }
    }];
}

#pragma mark - OTMDateAndTimePickerDelegate

- (void)dateAndTimePicker:(OTMDateAndTimeViewController *)picker
       didPickObservation:(OTMLocationObservation*)observation
{
    [self focusOnObservation:observation selected:NO];
}

#pragma mark - OTMSourcePickerControllerDelegate

- (void)sourcePicker:(OTMSourcePickerController *)picker
        pickedSource:(id<OTMSource>)source
           inSection:(OTMSourceSection)section
{
    picker.selectedSource = source;

    BOOL showPeerConfig = NO;
    BOOL showBeaconConfig = NO;

    switch (section) {
        case OTMSourceSectionOwn:
            self.selectedPeer = nil;
            self.selectedBeacons = nil;
            break;
            
        case OTMSourceSectionPeers:
            if (source.referenceObject) {
                self.selectedPeer = source.referenceObject;
                self.selectedBeacons = nil;
            } else {
                showPeerConfig = YES;
            }
            break;

        case OTMSourceSectionBeacons:
            if (source.referenceObject) {
                self.selectedPeer    = nil;
                self.selectedBeacons = source.referenceObject;
            } else {
                showBeaconConfig = YES;
            }
            break;
    }

    [self hideObservationSourcePicker:self];
    
    if (showPeerConfig) {
        [self showConnectWithPeers:self];
    } else if (showBeaconConfig) {
        [self showBeaconsLedger:self];
    } else {
        [self pickLatestObservationFromCurrentSource];
    }
}

#pragma mark - OTMLocationManagerDelegate

- (void)locationManager:(OTMLocationManager *)manager enqueuedObservation:(OTMLocationObservation *)observation
{
    /*if (self.lastAcquiredLocationAnnotation.observation != observation) {
        [self.mapView removeAnnotation:self.lastAcquiredLocationAnnotation];
    }
    
    self.lastAcquiredLocationAnnotation = [[OTMMapAnnotation alloc] initWithObservation:observation];
    
    [self.mapView addAnnotation:self.lastAcquiredLocationAnnotation];*/
}

@end
