//
//  Message_Private.h
//  CIXClient
//
//  Created by Steve Palmer on 05/11/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#ifndef CIXClient_Message_Private_h
#define CIXClient_Message_Private_h

#import "Message.h"

/* Private Message class accessors
 */
@interface Message (Private)
    -(void)setLevel:(int)value;
    -(void)setLastChildMessage:(Message *)value;
    -(Message *)lastChildMessage;
    -(int)innerSetIgnored;
    -(void)innerSetPriority;
    -(void)sync;
@end

#endif
