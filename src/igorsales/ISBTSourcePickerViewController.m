//
//  ISBTSourcePickerViewController.m
//  BTConnTest
//
//  Created by Igor Sales on 2015-08-27.
//  Copyright (c) 2015 igorsales.ca. All rights reserved.
//

#import "ISBTSourcePickerViewController.h"
#import "ISAudioPortMonitor.h"

@interface ISBTSourcePickerViewController ()

@property (nonatomic, strong) NSArray* portNames;
@property (nonatomic, strong) NSMutableSet* discoveredPortNames;
@property (nonatomic, strong) NSMutableSet* selectedPortNames;

@end

@implementation ISBTSourcePickerViewController

#pragma mark - Private

- (void)rebuildPortNames
{
    if (!self.discoveredPortNames) {
        self.discoveredPortNames = [NSMutableSet new];
    }
    
    [self.discoveredPortNames addObjectsFromArray:self.audioPortMonitor.discoveredPortNames];
    [self.discoveredPortNames addObjectsFromArray:self.selectedPortNames.allObjects];

    self.portNames = [self.discoveredPortNames.allObjects sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.selectedPortNames   = [NSMutableSet setWithArray:self.audioPortMonitor.monitoredPortNames];
    [self rebuildPortNames];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(audioConnectivityChangedNotification:)
                                                 name:ISAudioPortMonitorConnectivityChangedNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:ISAudioPortMonitorConnectivityChangedNotification
                                                  object:nil];
    [super viewWillDisappear:animated];
}

#pragma mark - Notifications

- (void)audioConnectivityChangedNotification:(NSNotification*)notification
{
    [self rebuildPortNames];
    [self.tableView reloadData];
}

#pragma mark - Actions

- (IBAction)commit:(id)sender
{
    // TODO: Use a real object instead of just the port name
    self.audioPortMonitor.monitoredPortNames = self.selectedPortNames.allObjects;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.discoveredPortNames.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];

    NSString* portName  = self.portNames[indexPath.row];
    cell.textLabel.text = portName;
    
    cell.accessoryType = [self.selectedPortNames containsObject:portName] ?
        UITableViewCellAccessoryCheckmark :
        UITableViewCellAccessoryNone;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSString* portName = self.portNames[indexPath.row];
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([self.selectedPortNames containsObject:portName]) {
        [self.selectedPortNames removeObject:portName];
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        [self.selectedPortNames addObject:portName];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
}

@end
