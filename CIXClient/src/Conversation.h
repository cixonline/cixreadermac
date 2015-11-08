//
//  Conversation.h
//  CIXClient
//
//  Created by Steve Palmer on 01/09/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "MailCollection.h"

@interface Conversation : TableBase {
    MailCollection * _messages;
}

@property ID_type ID;
@property int remoteID;
@property NSString * author;
@property NSDate * date;
@property NSString * subject;
@property BOOL unread;
@property BOOL readPending;
@property BOOL deletePending;
@property BOOL lastError;

// Accessors
-(MailCollection *)messages;
-(void)markRead;
-(void)markUnread;
-(void)markDelete;
-(void)sync;
@end
