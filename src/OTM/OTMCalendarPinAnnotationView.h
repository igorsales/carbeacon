//
//  OTMCalendarPinAnnotationView.h
//  BTConnTest
//
//  Created by Igor Sales on 2015-10-17.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface OTMCalendarPinAnnotationView : MKAnnotationView

@property (nonatomic, weak) IBOutlet UILabel* monthLabel;
@property (nonatomic, weak) IBOutlet UILabel* dayLabel;
@property (nonatomic, weak) IBOutlet UILabel* timeLabel;

@end
