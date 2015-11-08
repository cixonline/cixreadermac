//
//  MailCollection.h
//  CIXClient
//
//  Created by Steve Palmer on 02/09/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "MailMessage.h"

@interface MailCollection : NSObject {
    NSMutableArray * _messages;
}

// Accessors
-(id)initWithArray:(NSArray *)arrayOfMessages;
-(void)add:(MailMessage *)message;
-(NSInteger)count;
-(NSArray *)allMessages;
-(MailMessage *)messageByID:(ID_type)messageID;
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])stackbuf count:(NSUInteger)len;
@end
