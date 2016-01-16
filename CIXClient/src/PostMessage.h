//
//  PostMessage.h
//  CIXClient
//
//  Created by Steve Palmer on 05/11/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "JSONModel.h"
#import "Attachment2.h"

#define PostMessage2FlagsReturnBody 1

@interface J_PostMessage : JSONModel

@property (strong, nonatomic) NSString * Forum;
@property (strong, nonatomic) NSString * Topic;
@property (strong, nonatomic) NSString * Body;
@property (assign, nonatomic) int MsgID;
@property (assign, nonatomic) BOOL MarkRead;
@property (assign, nonatomic) int Flags;
@property (strong, nonatomic) NSArray<J_Attachment2, Optional> * Attachments;

@end
