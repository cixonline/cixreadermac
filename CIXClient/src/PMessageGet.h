//
//  PMessageGet.h
//  CIXClient
//
//  Created by Steve Palmer on 23/09/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "JSONModel.h"

@protocol J_PMessage
@end

@interface J_PMessage : JSONModel

@property (assign, nonatomic) int MessageID;
@property (strong, nonatomic) NSString * Body;
@property (strong, nonatomic) NSString * Date;
@property (strong, nonatomic) NSString * Sender;
@property (strong, nonatomic) NSString * Recipient;

@end

@interface J_PMessageSet : JSONModel

@property (strong, nonatomic) NSArray<J_PMessage, Optional> * PMessages;
@property (assign, nonatomic) int Count;
@property (assign, nonatomic) NSString * Subject;

@end
