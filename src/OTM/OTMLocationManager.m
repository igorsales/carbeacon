//
//  OTMLocationManager.m
//  BTConnTest
//
//  Created by Igor Sales on 2015-10-06.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import "OTMLocationManager.h"
#import "ISNotesManager.h"
#import "OTMDataModel.h"
#import "OTMPeerSharingLedger.h"
#import "OTMLocationObservation.h"
#import "OTMLocationDatabase.h"
#import <CoreLocation/CoreLocation.h>


#define IS_LOG_TO_FILE 1
#define IS_LOG_LEVEL IS_LOG_LEVEL_DEBUG
#import "ISLog.h"


@interface OTMLocationManager()

@property (nonatomic, strong) NSMutableArray* pendingObservations;
@property (nonatomic, strong) dispatch_queue_t queue;

@end

@implementation OTMLocationManager

#pragma mark - Setup/teardown

- (id)initWithSharingCategory:(NSString *)sharingCategory
{
    if (self = [super init]) {
        _sharingCategory = [sharingCategory copy];
        _pendingObservations = [NSMutableArray new];
        _timeoutToResend = 60.0; // try again after this amount
        
        [self createQueue];
    }

    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        _sharingCategory = [aDecoder decodeObjectForKey:@"sharingCategory"];
        _pendingObservations = [aDecoder decodeObjectForKey:@"pendingObservations"];
        if (!_pendingObservations) {
            _pendingObservations = [NSMutableArray new];
        }
        _timeoutToResend = [aDecoder decodeDoubleForKey:@"timeoutToResend"];
        if (_timeoutToResend <= 0.0) {
            _timeoutToResend = 60.0;
        }

        [self createQueue];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.sharingCategory forKey:@"sharingCategory"];
    [aCoder encodeObject:self.pendingObservations forKey:@"pendingObservations"];
    [aCoder encodeDouble:self.timeoutToResend forKey:@"timeoutToResend"];
}

#pragma mark - Accessors

- (void)setNotesManager:(ISNotesManager *)notesManager
{
    if (_notesManager != notesManager) {
        __block dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        __block id noteObject = nil;
        dispatch_barrier_async(self.queue, ^{
            ISLogInfo(@"Waiting for notes manager to be ready");
            dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
            ISLogInfo(@"Notes manager ready. Proceeding to posting locations");
            sem = nil;
            
            [[NSNotificationCenter defaultCenter] removeObserver:noteObject];
            noteObject = nil;
        });
        
        if (notesManager.ready) {
            dispatch_semaphore_signal(sem);
        } else {
            noteObject = [[NSNotificationCenter defaultCenter] addObserverForName:kISNotesManagerReadyNotification
                                                                           object:notesManager
                                                                            queue:nil
                                                                       usingBlock:^(NSNotification*  note) {
                                                                           dispatch_semaphore_signal(sem);
                                                                       }];
        }
        _notesManager = notesManager;
    }
}

#pragma mark - Operations

- (void)flush
{
    NSArray* recipients = [[self.model.ledger usersAllowedToReceive:self.sharingCategory] copy];

    [self.pendingObservations enumerateObjectsUsingBlock:^(OTMLocationObservation* obs, NSUInteger idx, BOOL* stop) {
        if (!obs.lastSendTimestamp ||
            -[obs.lastSendTimestamp timeIntervalSinceNow] >= self.timeoutToResend) {
            [self dispatchObservation:obs toRecipients:recipients];
        }
    }];
}

#pragma mark - Private

- (void)createQueue
{
    _queue = dispatch_queue_create("ca.igorsales.otm.LocationManager", DISPATCH_QUEUE_CONCURRENT);
}

- (void)enqueueLocation:(CLLocation*)location fromBeaconUUIDString:(NSString*)beaconUUIDString
{
    // TODO: Check the back of the queue for similar locations within the same period
    OTMLocationObservation* obs = [[OTMLocationObservation alloc] initWithLocation:location];
    obs.beaconUUIDString = beaconUUIDString;

    [self.model.database addObservation:obs];
    [self.pendingObservations addObject:obs];
    
    OTMPeerSharingLedger* ledger = self.model.ledger;
    NSArray* recipients = [[ledger usersAllowedToReceive:self.sharingCategory] copy];

    // send it right away
    [self dispatchObservation:obs toRecipients:recipients];
    [self.model serialize];
    
    if ([self.delegate respondsToSelector:@selector(locationManager:enqueuedObservation:)]) {
        [self.delegate locationManager:self enqueuedObservation:obs];
    }
}

- (void)dispatchObservation:(OTMLocationObservation*)obs toRecipients:(NSArray*)recipients
{
    if (obs.sending) {
        return;
    }
    
    obs.sending = YES;
    dispatch_async(self.queue, ^{
        [self sendObservation:obs toRecipients:recipients];
    });
}

- (void)dequeueObservation:(OTMLocationObservation*)observation
{
    [self.pendingObservations removeObject:observation];
    [self.model serialize];
}

- (void)requeueObservation:(OTMLocationObservation*)observation
{
    // push to the end of the queue
    [self.pendingObservations removeObject:observation];

    if (observation.numberOfSendTries > 5) {
        ISLogWarn(@"Giving up sending observation %@ after %@ tries", observation, @(observation.numberOfSendTries));
        // TODO: Inform server/analytics somehow
        return;
    }

    [self.pendingObservations addObject:observation];
    [self.model serialize];
    
    observation.sending = NO;
}

- (void)sendObservation:(OTMLocationObservation*)observation toRecipients:(NSArray*)recipients
{
    ISLogInfo(@"started");

    __block UIBackgroundTaskIdentifier taskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        if (taskId != UIBackgroundTaskInvalid) {
            ISLogWarn(@"terminated early by system");
            [[UIApplication sharedApplication] endBackgroundTask:taskId];
        }
    }];
    
    if (taskId == UIBackgroundTaskInvalid) {
        ISLogWarn(@"Cannot get background task Id to push data to server");
    }
    
    observation.lastSendTimestamp = [NSDate date];
    observation.numberOfSendTries++;

    NSData* JSONData = [observation JSONData];

    if (!JSONData) {
        ISLogError(@"Error creating message!");
        [self requeueObservation:observation];
    } else {
        [recipients enumerateObjectsUsingBlock:^(NSString* userId, NSUInteger idx, BOOL* stop) {
            [self.notesManager encryptAndSendMessageData:JSONData
                                                      to:userId
                                         completionBlock:^(NSError *error) {
                                             if (error) {
                                                 ISLogError(@"Push to %@ responded with error %@", userId, error);
                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                     [self requeueObservation:observation];
                                                 });
                                             } else {
                                                 observation.sentSuccessfully = YES;
                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                     if ([self.delegate respondsToSelector:@selector(locationManager:didSend:)]) {
                                                         [self.delegate locationManager:self
                                                                                didSend:observation];
                                                     }
                                                     [self dequeueObservation:observation];
                                                 });
                                             }
                                         }];
        }];
    }

    if (taskId != UIBackgroundTaskInvalid) {
        ISLogInfo(@"finished normally");
        [[UIApplication sharedApplication] endBackgroundTask:taskId];
    }
}

#pragma mark - ISLocationManagerDelegate

- (void)locationMonitor:(OTMLocationMonitor *)monitor
     didAcquireLocation:(CLLocation *)location
         withBeaconUUID:(NSUUID*)beaconUUID
{
    [self enqueueLocation:location fromBeaconUUIDString:beaconUUID.UUIDString];
}

@end
