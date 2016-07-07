//
//  OTMConnectViewController.m
//  OCTM
//
//  Created by Igor Sales on 2015-10-02.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import "OTMConnectViewController.h"
#import "OTMConstants.h"
#import "OTMPeerSharingLedger.h"
#import "ISNotesManager.h"
#import "ISPeerMessage.h"
#import "OTMConnectPeerCell.h"
#import "UIImage+Tint.h"
#import "NSString+UUIDColour.h"
#import "OTMTitleView.h"

#import <MultipeerConnectivity/MultipeerConnectivity.h>

// TODO: Re-factor this class!

#define kServiceType @"is-octm-peers"
#define kPeerIdKey   @"kISMCPeerIDForPeerConnect"
#define kPeerTimeout (5.5)


@interface OTMConnectViewController () <UITableViewDataSource,
                                        MCNearbyServiceAdvertiserDelegate,
                                        MCNearbyServiceBrowserDelegate,
                                        MCSessionDelegate>

@property (nonatomic, strong) MCPeerID*                   thisPeerID;
@property (nonatomic, strong) MCNearbyServiceAdvertiser*  advertiser;
@property (nonatomic, strong) MCNearbyServiceBrowser*     browser;
@property (nonatomic, strong) MCSession*                  session;

@property (nonatomic, strong) NSMutableSet*               discoveredPeers;

@property (nonatomic, strong) NSMutableArray*             requests;

@end

@implementation OTMConnectViewController

#pragma mark - Setup/teardown

- (void)dealloc
{
    [self disconnectSession];
}

#pragma mark - Overrides

- (void)viewDidLoad
{
    [super viewDidLoad];

    UINib* nib = [UINib nibWithNibName:@"TitleView" bundle:nil];
    [self.tableView registerNib:nib forHeaderFooterViewReuseIdentifier:@"titleHeaderView"];
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Chalkboard"]];

    [self initializeDisplayName];
    [self initializePeer];
    [self initializeSession];
    [self initializeRequests];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Chalkboard"]];
    self.navigationController.navigationBar.translucent = YES;
    
    self.navigationController.navigationBar.titleTextAttributes = @{
        NSFontAttributeName: [UIFont fontWithName:@"Chalkduster" size:19],
        NSForegroundColorAttributeName: [UIColor whiteColor]
    };
    
    [self startLookingForPeers];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self stopLookingForPeers];

    [super viewWillDisappear:animated];
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

#pragma mark - Private

- (void)initializeSession
{
    self.session = [[MCSession alloc] initWithPeer:self.thisPeerID
                                  securityIdentity:nil
                              encryptionPreference:MCEncryptionNone];
    self.session.delegate = self;
}

- (void)initializeDisplayName
{
    if (!self.displayName) {
        self.displayName = [UIDevice currentDevice].name;
    }
}

- (void)initializePeer
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSData* peerIDData = [defaults dataForKey:kPeerIdKey];
    if (peerIDData) {
        MCPeerID* peerID = [NSKeyedUnarchiver unarchiveObjectWithData:peerIDData];
        if (peerID && [peerID isKindOfClass:[MCPeerID class]]) {
            self.thisPeerID = peerID;
        }
    }
    
    if (!self.thisPeerID) {
        self.thisPeerID = [[MCPeerID alloc] initWithDisplayName:self.displayName];
        peerIDData = [NSKeyedArchiver archivedDataWithRootObject:self.thisPeerID];
        [defaults setObject:peerIDData forKey:kPeerIdKey];
        [defaults synchronize];
    }
}

- (void)initializeRequests
{
    self.requests = [NSMutableArray new];
}

- (void)startLookingForPeers
{
    if (self.advertiser) {
        return;
    }
    
    NSDictionary* discoveryInfo = @{
                                                          @"userId": self.userId
                                                          };

    self.advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.thisPeerID
                                                        discoveryInfo:discoveryInfo
                                                          serviceType:kServiceType];
    self.advertiser.delegate = self;
    
    self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.thisPeerID
                                                    serviceType:kServiceType];
    self.browser.delegate = self;
    
    self.discoveredPeers = [NSMutableSet new];
    
    [self.advertiser startAdvertisingPeer];
    [self.browser startBrowsingForPeers];
}

- (void)stopLookingForPeers
{
    if (!self.advertiser) {
        return;
    }
    
    [self.advertiser stopAdvertisingPeer];
    self.advertiser = nil;
    
    [self.browser stopBrowsingForPeers];
    self.browser = nil;
    
    self.discoveredPeers = nil;
}

- (void)disconnectSession
{
    [self.session disconnect];
}

- (void)startRequestingPublicKeyFromPeerAtIndex:(NSInteger)index
{
    NSDictionary* dict = self.discoveredPeers.allObjects[index];
    
    MCPeerID* peerID = dict[@"peerID"];
    
    if (![[self.session connectedPeers] containsObject:peerID]) {
        [self.browser invitePeer:peerID
                       toSession:self.session
                     withContext:[self.userId dataUsingEncoding:NSUTF8StringEncoding]
                         timeout:kPeerTimeout];
    }

    [self requestPublicKeyFromPeerID:peerID];
}

- (NSString*)peerUserIdForPeerID:(MCPeerID*)peerID
{
    __block NSString* userId = nil;
    [self.discoveredPeers enumerateObjectsUsingBlock:^(NSDictionary* dict, BOOL* stop) {
        if ([dict[@"peerID"] isEqual:peerID]) {
            *stop = YES;
            userId = dict[@"userId"];
        }
    }];

    return userId;
}

- (NSString*)nameForPeerID:(MCPeerID*)peerID
{
    __block NSString* userId = nil;
    [self.discoveredPeers enumerateObjectsUsingBlock:^(NSDictionary* dict, BOOL* stop) {
        if ([dict[@"peerID"] isEqual:peerID]) {
            *stop = YES;
            userId = dict[@"name"];
        }
    }];
    
    return userId;
}

- (void)requestPublicKeyFromPeerID:(MCPeerID*)peerID
{
    ISPeerMessage* req = [ISPeerMessage requestWithBody:@"needPublicKey"
                                               toTarget:peerID];

    @synchronized(self) {
        [self.requests addObject:req];
    }
    
    [self processNextRequest];
}

- (void)processNextRequest
{
    @synchronized(self) {
        if (!self.requests.count) {
            return;
        }
        
        [self.requests enumerateObjectsUsingBlock:^(ISPeerMessage* request, NSUInteger idx, BOOL* stop) {
            if (!request.sent && [self.session.connectedPeers containsObject:request.target]) {
                NSData* reqData = [NSKeyedArchiver archivedDataWithRootObject:request];
                
                __autoreleasing NSError* error = nil;
                [self.session sendData:reqData
                               toPeers:@[request.target]
                              withMode:MCSessionSendDataReliable
                                 error:&error];
                if (!error) {
                    request.sent = YES;
                } else {
                    NSLog(@"Not able to send request: %@", request);
                }
                *stop = YES;
            }
        }];
    }
}

- (void)processMessage:(ISPeerMessage*)message fromPeer:(MCPeerID*)peerID
{
    switch (message.type) {
        case ISPeerMessageTypeRequest:  [self processRequest:message from:peerID];  break;
        case ISPeerMessageTypeResponse: [self processResponse:message from:peerID]; break;
            
        default:
            NSLog(@"Invalid message type: %d", message.type);
            break;
    }
}

- (void)processRequest:(ISPeerMessage*)request from:(MCPeerID*)peerID;
{
    NSLog(@"processing request %@", request);

    NSString* peerUserID = [self peerUserIdForPeerID:peerID];

    ISPeerMessage* response = nil;
    if ([request.body isEqual:@"needPublicKey"]) {
        // force key re-generation since this is a "new" connection
        [self.notesManager generateKeyPairForPeerUserId:peerUserID];
        NSData* keyData   = [self.notesManager publicKeyDataForPeerUserId:peerUserID outbound:YES];
        NSData* signature = [self.notesManager signString:@"needPublicKey" withPeerUserId:peerUserID];
        
        response = [request responseWithBody:@{
                                               @"publicKey": keyData,
                                               @"signature": signature ? signature : [NSNull null]
                                               }];
    }
    
    if (!response) {
        NSLog(@"No response for request %@", request);
        return;
    }

    NSData* msgData = [NSKeyedArchiver archivedDataWithRootObject:response];
    
    if (![self.session.connectedPeers containsObject:peerID]) {
        NSLog(@"Not connected. Cannot reply");
    }
    
    __autoreleasing NSError* error = nil;
    [self.session sendData:msgData
                   toPeers:@[peerID]
                  withMode:MCSessionSendDataReliable
                     error:&error];
    
    if (error) {
        NSLog(@"processRequest send error %@", error);
    }
}

- (ISPeerMessage*)requestWithID:(int32_t)messageId
{
    __block ISPeerMessage* message = nil;

    @synchronized(self) {
        [self.requests enumerateObjectsUsingBlock:^(ISPeerMessage* msg, NSUInteger idx, BOOL* stop) {
            if (msg.messageId == messageId) {
                message = msg;
                *stop = YES;
            }
        }];
    }

    return message;
}

- (void)processResponse:(ISPeerMessage*)response from:(MCPeerID*)peerID;
{
    NSLog(@"Processing response %@", response);

    ISPeerMessage* request = [self requestWithID:response.messageId];
    if (!request) {
        NSLog(@"Cannot find request with id %d", response.messageId);
        return;
    }
    
    do {
        if (![peerID isEqual:request.target]) {
            NSLog(@"Mismatch between request and response");
            break;
        }

        NSString* peerUserID = [self peerUserIdForPeerID:peerID];
        
        if (![response.body isKindOfClass:[NSDictionary class]]) {
            NSLog(@"Invalid response ");
            break;
        }
        
        NSData* publicKeyData = response.body[@"publicKey"];
        NSData* signature     = response.body[@"signature"];

        [self.notesManager installPublickKeyData:publicKeyData forPeerUserId:peerUserID];
        
        if (!signature || [signature isEqual:[NSNull null]]) {
            NSLog(@"No signature found on the response");
        } else {
            if (![self.notesManager verifyString:@"needPublicKey"
                                       signature:signature
                                  fromPeerUserId:peerUserID]) {
                NSLog(@"Uh-oh. Key pair doesn't match. Not installing.");
                break;
            } else {
                NSLog(@"Ok. public key seems to work properly");
            }
        }
        
        if (![publicKeyData isKindOfClass:[NSData class]] || !publicKeyData.length) {
            NSLog(@"Invalid public key data");
            break;
        }
        
        NSString* name = [self nameForPeerID:peerID];
        if (!name) {
            name = NSLocalizedString(@"Unknown",nil);
        }
        
        [self.ledger allowUserId:peerUserID
                    asReceiverOf:kOTMPeerSharingCategoryCarLocation
                     withOptions:@{ @"name": name }];
        
        NSLog(@"Adding '%@' (%@) to list of allowed receivers", peerUserID, name);

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    } while (NO);
    
    @synchronized(self) {
        [self.requests removeObject:request];
    }
}

- (void)flushRequestsTo:(MCPeerID*)peerID
{
    @synchronized(self) {
        [self.requests filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(ISPeerMessage* message, NSDictionary* bindings) {
            return ![peerID isEqual:message.target];
        }]];
    }
}

#pragma mark - MCNearbyServiceAdvertiserDelegate

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error
{
    NSLog(@"Error advertising as a peer: %@", error);
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID
       withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession * _Nonnull))invitationHandler
{
    NSLog(@"Peer UserId: %@", [[NSString alloc] initWithData:context encoding:NSUTF8StringEncoding]);
    
    invitationHandler(YES, self.session);
}

#pragma mark - MCNearbyServiceBrowserDelegate

- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error
{
    NSLog(@"Error when browsing for peers: %@", error);
}

- (void)browser:(MCNearbyServiceBrowser *)browser
      foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary*)info
{
    [self.discoveredPeers addObject:@{
                                      @"peerID": peerID,
                                      @"name":   peerID.displayName,
                                      @"userId": info[@"userId"]
                                      }];
    
    [self.tableView reloadData];
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    __block NSDictionary* dict = nil;
    [self.discoveredPeers enumerateObjectsUsingBlock:^(id obj, BOOL* stop) {
        if ([obj[@"peerID"] isEqual:peerID]) {
            dict = obj;
            *stop = YES;
        }
    }];
    
    if (dict) {
        [self.discoveredPeers removeObject:dict];
        [self.tableView reloadData];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0: return NSLocalizedString(@"Nearby peers", nil);
        case 1: return NSLocalizedString(@"Peers authorized to receive my location", nil);
    }
    
    return nil;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    OTMTitleView* view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"titleHeaderView"];
    
    view.titleLabel.text = [self tableView:tableView titleForHeaderInSection:section];
    
    return view;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows = 0;

    switch (section) {
        case 0: // Nearby peers
            return MAX(1,self.discoveredPeers.count);
            break;
            
        case 1: // Authorized peers
            rows = [self.ledger usersAllowedToReceive:kOTMPeerSharingCategoryCarLocation].count;
            rows = MAX(1,rows);
            break;
            
        default:
            break;
    }

    return self.discoveredPeers.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTMConnectPeerCell* cell = [tableView dequeueReusableCellWithIdentifier:@"peerCell"
                                                               forIndexPath:indexPath];
    cell.phoneImageView.hidden = NO;
    
    switch (indexPath.section) {
        case 0: // Nearby peers
            if (self.discoveredPeers.count) {
                cell.nameLabel.text        = self.discoveredPeers.allObjects[indexPath.row][@"name"];
                cell.beaconUUIDLabel.text  = self.discoveredPeers.allObjects[indexPath.row][@"userId"];
                cell.beaconUUIDLabel.text  = cell.beaconUUIDLabel.text.lowercaseString;
            } else {
                cell.nameLabel.text        = NSLocalizedString(@"None.", nil);
                cell.beaconUUIDLabel.text  = nil;
                cell.phoneImageView.hidden = YES;
            }
            break;
            
        case 1: // Authorized users
            if ([self.ledger usersAllowedToReceive:kOTMPeerSharingCategoryCarLocation].count) {
                NSString*     userId = [self.ledger usersAllowedToReceive:kOTMPeerSharingCategoryCarLocation][indexPath.row];
                NSDictionary* opts   = [self.ledger optionsToReceive:kOTMPeerSharingCategoryCarLocation
                                                             forUser:userId];
                
                cell.nameLabel.text = opts[@"name"];
                cell.beaconUUIDLabel.text = userId.lowercaseString;
            } else {
                cell.nameLabel.text        = NSLocalizedString(@"None.", nil);
                cell.beaconUUIDLabel.text  = nil;
                cell.phoneImageView.hidden = YES;
            }
            break;
            
        default:
            break;
    }
    
    cell.phoneImageView.image = [[UIImage imageNamed:@"Phone"] imageTintedWithColor:cell.beaconUUIDLabel.text.UUIDColor];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];

    switch (indexPath.section) {
        case 0: // Nearby users - Add to ledger
            if (self.discoveredPeers.count) {
                [self startRequestingPublicKeyFromPeerAtIndex:indexPath.row];
            }
            break;
            
        case 1: // Authorized users - Remove from ledger
            if (cell.detailTextLabel.text.length) {
                [self.ledger preventUser:cell.detailTextLabel.text
                           fromReceiving:kOTMPeerSharingCategoryCarLocation];
            }
            break;
            
        default:
            break;
    }

    [tableView reloadData];
}

#pragma mark - MCSessionDelegate

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    switch (state) {
        case MCSessionStateConnected:
            // Only send if we are requesting it in the first place.
            [self processNextRequest];
            break;
            
        case MCSessionStateNotConnected:
            [self flushRequestsTo:peerID];
            break;
            
        default:
            break;
    }
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    ISPeerMessage* message = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if (![message isKindOfClass:[ISPeerMessage class]]) {
        NSLog(@"Invalid message received");
        return;
    }
    
    [self processMessage:message fromPeer:peerID];
    [self processNextRequest];
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    NSAssert(NO, @"Not implemented");
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    NSAssert(NO, @"Not implemented");
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    NSAssert(NO, @"Not implemented");
}

@end
