//
//  ConversationCollection.h
//  CIXClient
//
//  Created by Steve Palmer on 01/09/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "Conversation.h"
#import "MailMessage.h"

/** The ConversationCollection class
 
 The ConversationCollection class aggregates the collection of all mail conversations
 and exposes interfaces to add, sync, remove and refresh individual conversations. The
 class exposes an enumerator allowing you to iterate over all conversations in the
 collection.
 */
@interface ConversationCollection : NSObject {
    NSMutableArray * _conversations;
    NSDate * _lastCheckDate;
}

// Accessors
-(id)initWithArray:(NSArray *)arrayOfConversations;
-(void)sync;
-(void)refresh;
-(void)add:(Conversation *)newConversation;
-(void)add:(Conversation *)newConversation withMessage:(MailMessage *)message;
-(void)remove:(Conversation *)conversation;
-(Conversation *)conversationByID:(ID_type)conversationID;
-(NSArray *)allConversations;
-(NSInteger)totalUnread;
-(NSInteger)totalUnreadPriority;
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])stackbuf count:(NSUInteger)len;
@end
