//
//  ConversationInboxSet.h
//  CIXClient
//
//  Created by Steve Palmer on 23/09/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "JSONModel.h"

@protocol J_ConversationInbox
@end

@interface J_ConversationInbox : JSONModel

@property (assign, nonatomic) int ID;
@property (strong, nonatomic) NSString * Body;
@property (strong, nonatomic) NSString * Date;
@property (strong, nonatomic) NSString * LastMsgBy;
@property (strong, nonatomic) NSString * Sender;
@property (strong, nonatomic) NSString * Subject;
@property (assign, nonatomic) BOOL Unread;

@end

@interface J_ConversationInboxSet : JSONModel

@property (strong, nonatomic) NSArray<J_ConversationInbox, Optional> * Conversations;
@property (assign, nonatomic) int Count;
@property (assign, nonatomic) int Start;

@end
