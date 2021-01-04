//
//  MessageCollection.h
//  CIXClient
//
//  Created by Steve Palmer on 17/10/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "Message.h"

@interface MessageCollection : NSObject {
    NSMutableArray * _threadedMessages;
    NSMutableArray * _messages;
    BOOL _isOrdered;
}

// Accessors
-(id)initWithArray:(NSArray *)arrayOfMessages;
-(void)add:(Message *)message;
-(BOOL)addInternal:(Message *)message;
-(void)delete:(Message *)message;
-(NSUInteger)count;
-(Message *)messageByID:(ID_type)messageID;
-(NSArray *)roots;
-(NSArray *)orderedMessages;
-(NSArray *)allMessages;
-(NSArray *)allmessagesByConversation;
-(NSArray *)childrenOfMessage:(Message *)message;
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])stackbuf count:(NSUInteger)len;
@end
