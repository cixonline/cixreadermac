//
//  PostMessage.h
//  CIXClient
//
//  Created by Steve Palmer on 05/11/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "JSONModel.h"
#import "Attachment2.h"

@interface J_PostMessage : JSONModel

@property (strong, nonatomic) NSString * Forum;
@property (strong, nonatomic) NSString * Topic;
@property (strong, nonatomic) NSString * Body;
@property (assign, nonatomic) int MsgID;
@property (assign, nonatomic) BOOL MarkRead;
@property (strong, nonatomic) NSArray<J_Attachment2, Optional> * Attachments;

@end
