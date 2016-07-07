//
//  ISPeerMessage.h
//  BTConnTest
//
//  Created by Igor Sales on 2015-10-08.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    ISPeerMessageTypeRequest,
    ISPeerMessageTypeResponse
} ISPeerMessageType;

@interface ISPeerMessage : NSObject <NSCoding>

@property (nonatomic, readonly) int32_t           messageId;
@property (nonatomic, readonly) ISPeerMessageType type;
@property (nonatomic, strong)   id                body;

// transient
@property (nonatomic, strong)   id                target;
@property (nonatomic, assign)   BOOL              sent;

+ (id)requestWithBody:(id)body toTarget:(id)target;
+ (id)responseWithBody:(id)body toTarget:(id)target;

- (id)responseWithBody:(id)body;

@end
