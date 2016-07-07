//
//  ISPeerMessage.m
//  BTConnTest
//
//  Created by Igor Sales on 2015-10-08.
//  Copyright © 2015 igorsales.ca. All rights reserved.
//

#import "ISPeerMessage.h"
#import <libkern/OSAtomic.h>

static volatile int32_t sSerial = 1;

@implementation ISPeerMessage

- (id)initWithType:(ISPeerMessageType)type body:(id)body target:(id)target
{
    if (self = [super init]) {
        _type = type;
        _body = body;
        _target = target;
        _messageId = OSAtomicIncrement32(&sSerial);
    }

    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        _type      = [aDecoder decodeIntForKey:@"type"];
        _messageId = [aDecoder decodeInt32ForKey:@"messageId"];
        _body      = [aDecoder decodeObjectForKey:@"body"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInt:_type forKey:@"type"];
    [aCoder encodeInt32:_messageId forKey:@"messageId"];
    [aCoder encodeObject:_body forKey:@"body"];
}

+ (id)requestWithBody:(id)body toTarget:(id)target
{
    return [[self alloc] initWithType:ISPeerMessageTypeRequest
                                 body:body
                               target:target];
}

+ (id)responseWithBody:(id)body toTarget:(id)target
{
    return [[self alloc] initWithType:ISPeerMessageTypeResponse
                                 body:body
                               target:target];
}

- (id)responseWithBody:(id)body
{
    ISPeerMessage* msg = [self.class responseWithBody:body toTarget:nil];
    
    msg->_messageId = self.messageId;
    
    return msg;
}

@end
