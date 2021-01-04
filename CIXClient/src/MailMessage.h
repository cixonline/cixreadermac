//
//  MailMessage.h
//  CIXClient
//
//  Created by Steve Palmer on 01/09/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "TableBase.h"

@interface MailMessage : TableBase

@property ID_type ID;
@property int remoteID;
@property NSString * recipient;
@property NSString * body;
@property NSDate * date;
@property ID_type conversationID;

// Accessors
-(BOOL)isDraft;
-(BOOL)isMine;
@end
