//
//  OTMConnectViewController.h
//  OCTM
//
//  Created by Igor Sales on 2015-10-02.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OTMPeerSharingLedger;
@class ISNotesManager;

@interface OTMConnectViewController : UITableViewController

@property (nonatomic, strong) ISNotesManager* notesManager;
@property (nonatomic, copy) NSString* userId;
@property (nonatomic, copy) NSString* publicKey;
@property (nonatomic, copy) NSString* displayName;

@property (nonatomic, copy) OTMPeerSharingLedger* ledger;

@end
