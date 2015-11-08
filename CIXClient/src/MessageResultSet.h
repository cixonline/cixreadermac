//
//  MessageResultSet.h
//  CIXClient
//
//  Created by Steve Palmer on 17/10/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "JSONModel.h"

@protocol J_Message2
@end

@interface J_Message2: JSONModel

@property (strong, nonatomic) NSString * Author;
@property (strong, nonatomic) NSString * Body;
@property (strong, nonatomic) NSString * DateTime;
@property (assign, nonatomic) NSString * Flag;
@property (strong, nonatomic) NSString * Forum;
@property (assign, nonatomic) int ID;
@property (assign, nonatomic) BOOL Priority;
@property (assign, nonatomic) int ReplyTo;
@property (assign, nonatomic) int RootID;
@property (assign, nonatomic) BOOL Starred;
@property (assign, nonatomic) BOOL Unread;
@property (strong, nonatomic) NSString * Topic;
@property (strong, nonatomic) NSString * LastUpdate;

@end

@interface J_MessageResultSet2 : JSONModel

@property (strong, nonatomic) NSArray<J_Message2, Optional> * Messages;
@property (assign, nonatomic) int Count;
@property (assign, nonatomic) int Start;

@end
