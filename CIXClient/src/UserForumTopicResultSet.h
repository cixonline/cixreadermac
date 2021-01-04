//
//  UserForumTopicResultSet.h
//  CIXClient
//
//  Created by Steve Palmer on 26/09/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "JSONModel.h"

#define UserForumTopicFlagsLive 0x0001
#define UserForumTopicFlagsReadOnly 0x0002
#define UserForumTopicFlagsArchived 0x0004
#define UserForumTopicFlagsCannotResign 0x0008
#define UserForumTopicFlagsNoticeboard 0x0010

@protocol J_UserForumTopic2
@end

@interface J_UserForumTopic2 : JSONModel

@property (assign, nonatomic) int Flags;
@property (strong, nonatomic) NSString * Forum;
@property (assign, nonatomic) int Msgs;
@property (assign, nonatomic) int Priority;
@property (strong, nonatomic) NSString * Topic;
@property (assign, nonatomic) int UnRead;
@property (strong, nonatomic) NSString * Recent;
@property (strong, nonatomic) NSString * Name;
@property (assign, nonatomic) BOOL Latest;

@end

@interface J_UserForumTopicResultSet2 : JSONModel

@property (strong, nonatomic) NSArray<J_UserForumTopic2, Optional> * UserTopics;
@property (assign, nonatomic) int Count;
@property (assign, nonatomic) int Start;

@end
