//
//  OTMCarPinAnnotationView.h
//  CarBeacon
//
//  Created by Igor Sales on 2015-10-28.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface OTMCarPinAnnotationView : MKAnnotationView

@property (nonatomic, weak) IBOutlet UIImageView* backgroundImageView;
@property (nonatomic, weak) IBOutlet UIImageView* carBodyImageView;
@property (nonatomic, weak) IBOutlet UIView*      licensePlateView;
@property (nonatomic, weak) IBOutlet UIImageView* licensePlateImageView;
@property (nonatomic, weak) IBOutlet UILabel*     licensePlateLabel;

@property (nonatomic, weak) IBOutlet UIView*      accuracyView;

- (void)setAccuracy:(CGFloat)accuracy onMapView:(MKMapView*)mapView animated:(BOOL)animated;

@end
