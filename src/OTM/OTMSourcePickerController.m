//
//  OTMSourcePickerController.m
//  CarBeacon
//
//  Created by Igor Sales on 2015-10-18.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import "OTMSourcePickerController.h"
#import "OTMSourceTableViewCell.h"
#import "OTMTitleView.h"
#import "OTMProximityView.h"
#import "UIImage+Tint.h"
#import "NSString+UUIDColour.h"

@interface _OTMSourceImpl : NSObject<OTMSource>

@property (nonatomic, copy) NSString* title;
@property (nonatomic, copy) NSString* subtitle;

@property (nonatomic, strong) id referenceObject;

@end

@implementation _OTMSourceImpl

@end


@interface OTMSourcePickerController ()

@property (nonatomic, assign) CGFloat shiftHeight;

@end

@implementation OTMSourcePickerController

+ (id<OTMSource>)sourceWithTitle:(NSString *)title subtitle:(NSString *)subtitle
{
    _OTMSourceImpl* s = [_OTMSourceImpl new];
    
    s.title = title;
    s.subtitle = subtitle;
    
    return s;
}

+ (id<OTMSource>)sourceWithTitle:(NSString *)title
{
    _OTMSourceImpl* s = [_OTMSourceImpl new];
    
    s.title = title;
    
    return s;
}

- (NSArray*)constraintsForView:(UIView*)view top:(BOOL)top bottom:(BOOL)bottom
{
    return [view.superview.constraints filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSLayoutConstraint* c, id bindings) {
        NSLayoutAttribute attr;

        if (c.firstItem == view) {
            attr = c.firstAttribute;
        } else if (c.secondItem == view) {
            attr = c.secondAttribute;
        }
        switch (attr) {
            case NSLayoutAttributeBottom:
            case NSLayoutAttributeBottomMargin:
                if (bottom) return YES;
                break;

            case NSLayoutAttributeTop:
            case NSLayoutAttributeTopMargin:
                if (top) return YES;
                break;

            default:
                break;
        }
        
        return NO;
    }]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UINib* nib = [UINib nibWithNibName:@"TitleView" bundle:nil];
    [self.tableView registerNib:nib forHeaderFooterViewReuseIdentifier:@"titleHeaderView"];
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Chalkboard"]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return self.ownSources.count;
            
        case 1:
            return self.peerSources.count;
            
        case 2:
            return self.beacons.count;
            
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTMSourceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"sourceCell" forIndexPath:indexPath];
    
    id<OTMSource> source = [self sourceForIndexPath:indexPath];

    cell.nameLabel.text       = source.title;
    cell.beaconUUIDLabel.text = source.subtitle.lowercaseString;

    UIColor* tint = source.subtitle.UUIDColor;
    if (tint) {
        cell.proximityView.tintColor = tint;
        if (self.selectedSource != source) {
            cell.proximityView.proximity = OTMProximityFar;
            tint = [tint colorWithAlphaComponent:0.16];
        } else {
            cell.proximityView.proximity = OTMProximityImmediate;
        }
        
        cell.phoneImageView.image  = [[UIImage imageNamed:@"Phone"] imageTintedWithColor:tint];
        cell.phoneImageView.hidden = indexPath.section == 2;
        cell.proximityView.hidden  = indexPath.section != 2;
    } else {
        cell.proximityView.hidden  = YES;
        cell.phoneImageView.hidden =  YES;
    }
    
    return cell;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return NSLocalizedString(@"From You", nil);
            
        case 1:
            return NSLocalizedString(@"From Your Peers", nil);
            
        case 2:
            return NSLocalizedString(@"From Your CarBeacons", nil);
            
        default:
            return nil;
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    OTMTitleView* view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"titleHeaderView"];

    view.titleLabel.text = [self tableView:tableView titleForHeaderInSection:section];
    
    return view;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    [self.delegate sourcePicker:self
                   pickedSource:[self sourceForIndexPath:indexPath]
                      inSection:(OTMSourceSection)indexPath.section];
    
    [tableView reloadData];
}

#pragma mark - Private

- (id<OTMSource>)sourceForIndexPath:(NSIndexPath*)indexPath
{
    switch (indexPath.section) {
        case 0: // You
            return self.ownSources[indexPath.row];
            
        case 1: // Your peers
            if (indexPath.row < self.peerSources.count) {
                return self.peerSources[indexPath.row];
            } else {
                return [OTMSourcePickerController sourceWithTitle:NSLocalizedString(@"Configure...", nil)
                                                         subtitle:nil];
            }
            
        case 2:
            if (indexPath.row < self.beacons.count) {
                return self.beacons[indexPath.row];
            } else {
                return [OTMSourcePickerController sourceWithTitle:NSLocalizedString(@"Configure...", nil)
                                                         subtitle:nil];
            }
            
        default:
            return nil;
    }
}

- (void)shiftView:(UIView*)view verticallyBy:(CGFloat)delta
{
    NSArray* topConstraints    = [self constraintsForView:view top:YES bottom:NO];
    NSArray* bottomConstraints = [self constraintsForView:view top:NO bottom:YES];

    [topConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint* c, NSUInteger idx, BOOL*  stop) {
        c.constant -= delta / c.multiplier;
    }];
    
    [bottomConstraints enumerateObjectsUsingBlock:^(NSLayoutConstraint* c, NSUInteger idx, BOOL*  stop) {
        c.constant -= delta / c.multiplier;
    }];
}

#pragma mark - Operations

- (void)slideFromBottomOntoViewController:(UIViewController*)viewController shiftView:(UIView*)shiftView
{
    NSAssert(shiftView, @"shiftView cannot be nil");
    
    self.shiftHeight = viewController.view.bounds.size.height / 2.0;
    CGRect ctrlerFrame     = CGRectMake(0, 0, 0, self.shiftHeight);
    
    // since the storyboard cannot give me controllers with certain sizes, we need to hardcode it here.
    ctrlerFrame.size.width  = viewController.view.bounds.size.width;
    ctrlerFrame.origin.y    = viewController.view.bounds.size.height - ctrlerFrame.size.height;
    
    self.view.frame = ctrlerFrame;
    
    [self shiftView:shiftView verticallyBy:self.shiftHeight];
    [shiftView setNeedsUpdateConstraints];

    [viewController addChildViewController:self];
    [viewController.view insertSubview:self.view belowSubview:shiftView];
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         [shiftView layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         
                     }];
}

- (void)slideOutShiftingViewBack:(UIView*)shiftView
{
    NSAssert(shiftView, @"shiftView cannot be nil");
    
    [self shiftView:shiftView verticallyBy:-self.shiftHeight];
    [shiftView setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         [shiftView layoutIfNeeded];
                     } completion:^(BOOL finished) {
                         [self.view removeFromSuperview];
                         [self removeFromParentViewController];
                     }];
}

@end
