//
//  OTMBeaconsListController.m
//  CarBeacon
//
//  Created by Igor Sales on 2015-11-02.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import "OTMBeaconsListController.h"
#import "OTMProximityView.h"
#import "NSString+UUIDColour.h"

@interface OTMBeaconsListController ()

@end

@implementation OTMBeaconsListController

#pragma mark - Operations

- (void)updateBeaconViews
{
    [self updateBeaconSubviews];
}

#pragma mark - Private

- (void)updateBeaconSubviews
{
    [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSInteger beaconCount = self.beacons.beaconUUIDStrings.count;
    CGFloat w = 16 + beaconCount * 32 + (beaconCount-1) * 8;
    __block CGFloat x = w - 8 - 32;
    [self.beacons.beaconUUIDStrings enumerateObjectsUsingBlock:^(NSString* UUID, NSUInteger idx, BOOL* stop) {
        OTMProximityView* beaconView = [[OTMProximityView alloc] initWithFrame:CGRectMake(x, 8,
                                                                                          32, 32)];
        beaconView.tintColor = UUID.UUIDColor;
        [self.view addSubview:beaconView];
        x -= 40;
    }];
    
    self.widthConstraint.constant = w;
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self updateBeaconSubviews];
}

#pragma mark - OTMLocationMonitorProximityViewSource

- (OTMProximityView*)proximityViewForBeaconUUID:(NSString*)UUID
{
    NSInteger index = [self.beacons.beaconUUIDStrings indexOfObject:UUID];
    
    if (index != NSNotFound && index < self.view.subviews.count) {
        return self.view.subviews[index];
    }
    
    return nil;
}

@end
