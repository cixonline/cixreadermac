//
//  ConversationOutboxSet.h
//  CIXClient
//
//  Created by Steve Palmer on 29/09/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "JSONModel.h"

@protocol J_ConversationOutbox
@end

@interface J_ConversationOutbox : JSONModel

@property (assign, nonatomic) int ID;
@property (strong, nonatomic) NSString * Body;
@property (strong, nonatomic) NSString * Date;
@property (strong, nonatomic) NSString * Recipient;
@property (strong, nonatomic) NSString * Subject;

@end

@interface J_ConversationOutboxSet : JSONModel

@property (strong, nonatomic) NSArray<J_ConversationOutbox, Optional> * Conversations;
@property (assign, nonatomic) int Count;
@property (assign, nonatomic) int Start;

@end
