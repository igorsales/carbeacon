//
//  OTMSourcePickerController.h
//  CarBeacon
//
//  Created by Igor Sales on 2015-10-18.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    OTMSourceSectionOwn,
    OTMSourceSectionPeers,
    OTMSourceSectionBeacons
} OTMSourceSection;

@protocol OTMSource <NSObject>

@property (nonatomic, readonly, copy) NSString* title;
@property (nonatomic, readonly, copy) NSString* subtitle;

@property (nonatomic, strong)         id referenceObject;

@end

@class OTMSourcePickerController;

@protocol OTMSourcePickerControllerDelegate <NSObject>

- (void)sourcePicker:(OTMSourcePickerController*)picker pickedSource:(id<OTMSource>)source inSection:(OTMSourceSection)section;

@end

@interface OTMSourcePickerController : UITableViewController

+ (id<OTMSource>)sourceWithTitle:(NSString*)title subtitle:(NSString*)subtitle;
+ (id<OTMSource>)sourceWithTitle:(NSString*)title;

@property (nonatomic, strong) NSArray* ownSources;
@property (nonatomic, strong) NSArray* peerSources;
@property (nonatomic, strong) NSArray* beacons;

@property (nonatomic, weak)   id<OTMSource> selectedSource;

@property (nonatomic, weak) id<OTMSourcePickerControllerDelegate> delegate;

// operations
- (void)slideFromBottomOntoViewController:(UIViewController*)viewController shiftView:(UIView*)view;
- (void)slideOutShiftingViewBack:(UIView*)view;


@end
