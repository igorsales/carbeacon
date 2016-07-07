//
//  OTMPeerSharingLedger.h
//  BTConnTest
//
//  Created by Igor Sales on 2015-10-03.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTMPeerSharingLedger : NSObject <NSCoding, NSCopying>

- (void)allowUserId:(NSString*)userId asReceiverOf:(NSString*)category withOptions:(NSDictionary*)options;
- (void)preventUser:(NSString*)userId fromReceiving:(NSString*)category;

- (NSArray*)usersAllowedToReceive:(NSString*)category;
- (NSDictionary*)optionsToReceive:(NSString*)category forUser:(NSString*)userId;

@end
