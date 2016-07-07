//
//  ViewController.h
//  BTConnTest
//
//  Created by Igor Sales on 2015-08-26.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class ISNotesManager;
@class OTMLocationMonitor;
@class OTMLocationManager;
@class ISDisclosureButton;
@class OTMProximityView;
@class OTMDataModel;
@class OTMBeaconsListController;

@interface OTMMapViewController : UIViewController

@property (nonatomic, strong)          OTMDataModel*             model;
@property (nonatomic, strong) IBOutlet OTMLocationMonitor*       locationMonitor;
@property (nonatomic, strong) IBOutlet ISNotesManager*           notesManager;
@property (nonatomic, strong) IBOutlet OTMBeaconsListController* beaconsController;

@property (nonatomic, strong)          OTMLocationManager* locationManager;

@property (nonatomic, weak)   IBOutlet UIView*             contentView;
@property (nonatomic, weak)   IBOutlet MKMapView*          mapView;
@property (nonatomic, weak)   IBOutlet ISDisclosureButton* observationSourceDisclosureButton;

- (IBAction)eraseLocations:(id)sender;

- (IBAction)applyChangesFromConnect:(UIStoryboardSegue*)segue;
- (IBAction)cancelChangesFromConnect:(UIStoryboardSegue*)segue;
- (IBAction)resetIdentity:(id)sender;

- (IBAction)toggleObservationSourcePicker:(id)sender;
- (IBAction)showObservationSourcePicker:(id)sender;
- (IBAction)hideObservationSourcePicker:(id)sender;

- (IBAction)showDateAndTimePicker:(id)sender;
- (IBAction)hideDateAndTimePicker:(id)sender;
- (IBAction)toggleDateAndTimePicker:(id)sender;

- (IBAction)showBeaconsLedger:(id)sender;
- (IBAction)showConnectWithPeers:(id)sender;
- (IBAction)showTasks:(id)sender;

@end

