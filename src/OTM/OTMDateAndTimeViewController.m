//
//  OTMDateAndTimeViewController.m
//  CarBeacon
//
//  Created by Igor Sales on 2015-10-18.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import "OTMDateAndTimeViewController.h"
#import "OTMCalendarHeaderView.h"
#import "OTMTimeTableViewCell.h"
#import "OTMLocationObservation.h"
#import "UIView+OTMDateAndTimeFormatter.h"

@interface OTMDateAndTimeViewController ()

@property (nonatomic, strong) NSDateFormatter* dateFormatter;

@end

@implementation OTMDateAndTimeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.dateFormatter = [NSDateFormatter new];

    UINib* nib = [UINib nibWithNibName:@"CalendarHeader"
                                bundle:nil];
    [self.tableView registerNib:nib forHeaderFooterViewReuseIdentifier:@"CalendarHeader"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Operations

// TODO: Use a better way to measure instead of these 109 hardcoded values below

- (void)slideFromRightOntoViewController:(UIViewController*)viewController view:(UIView *)view
{
    if (!view) {
        view = viewController.view;
    }

    CGRect viewFrame       = view.bounds;
    CGRect statusBarFrame  = [UIApplication sharedApplication].statusBarFrame;
    __block CGRect newCtrlerRect   = self.view.frame;
    
    // since the storyboard cannot give me controllers with certain sizes, we need to hardcode it here.
    newCtrlerRect.size.width  = 109;
    newCtrlerRect.origin.y    = statusBarFrame.size.height;
    newCtrlerRect.origin.x    = viewFrame.size.width - newCtrlerRect.size.width + 117;
    newCtrlerRect.size.height = viewFrame.size.height - statusBarFrame.size.height - 64;
    
    self.view.frame = newCtrlerRect;
    
    [viewController addChildViewController:self];
    [view addSubview:self.view];
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         newCtrlerRect.origin.x = newCtrlerRect.origin.x - 109;
                         self.view.frame = newCtrlerRect;
                     }
                     completion:^(BOOL finished) {
                         
                     }];
}

- (void)slideOut
{
    CGRect frame = self.view.frame;
    
    frame.origin.x += 109;
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.view.frame = frame;
                     } completion:^(BOOL finished) {
                         [self.view removeFromSuperview];
                         [self removeFromParentViewController];
                     }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.dataSource observationDays].count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSDate* day = [self.dataSource observationDays][section];
    
    return [self.dataSource observationsForDay:day].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTMTimeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TimeHolder"
                                                                 forIndexPath:indexPath];
    
    NSDate* day = [self.dataSource observationDays][indexPath.section];
    OTMLocationObservation* obs = [self.dataSource observationsForDay:day][indexPath.row];
    
    [cell formatWithDate:obs.location.timestamp];

    return cell;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    OTMCalendarHeaderView* view = (OTMCalendarHeaderView*)[self.tableView dequeueReusableHeaderFooterViewWithIdentifier:@"CalendarHeader"];
    
    NSDate* day = [self.dataSource observationDays][section];
    
    [view formatWithDate:day];
    
    return view;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDate* day = [self.dataSource observationDays][indexPath.section];
    OTMLocationObservation* obs = [self.dataSource observationsForDay:day][indexPath.row];
    
    [self.delegate dateAndTimePicker:self didPickObservation:obs];
}

@end
