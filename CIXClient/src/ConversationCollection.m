//
//  ConversationCollection.m
//  CIXClient
//
//  Created by Steve Palmer on 01/09/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "CIX.h"
#import "FMDatabase.h"
#import "ConversationInboxSet.h"
#import "ConversationOutboxSet.h"
#import "PMessageGet.h"
#import "StringExtensions.h"

@implementation ConversationCollection

/* Default initialiser. Set the default check date for new
 * inbox messages.
 */
-(id)init
{
    if ((self = [super init]) != nil)
        _lastCheckDate = [NSDate dateWithTimeIntervalSince1970:0];
    return self;
}

/* Synchronise the conversations collection.
 */
-(void)sync
{
    if (CIX.online)
    {
        @try {
            [self postMessages];
            [self refresh];
        }
        @catch (NSException *exception) {
            [CIX reportServerExceptions:__PRETTY_FUNCTION__ exception:exception];
        }
    }
}

/* Run the post message sync task. For every conversation that has
 * a draft pending, we sync it.
 */
-(void)postMessages
{
    for (Conversation * conversation in self.conversations)
        [conversation sync];
}

/* Run a refresh sync task.
 */
-(void)refresh
{
    NSString * sinceDate = [[CIX dateFormatter] stringFromDate:_lastCheckDate];
    NSURLRequest * inboxRequest = [APIRequest get:@"personalmessage/inbox" withQuery:[NSString stringWithFormat:@"since=%@", sinceDate]];
    if (inboxRequest != nil)
    {
        NSURLSession * session = [NSURLSession sharedSession];
        NSURLSessionDataTask * task = [session dataTaskWithRequest:inboxRequest
                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                       {
                                           if (error != nil)
                                               [CIX reportServerErrors:__PRETTY_FUNCTION__ error:error];
                                           else
                                           {
                                               JSONModelError * jsonError = nil;
                                               NSMutableArray * inboxSet = [NSMutableArray array];
                                               
                                               J_ConversationInboxSet * inbox = [[J_ConversationInboxSet alloc] initWithData:data error:&jsonError];
                                               if (jsonError == nil)
                                               {
                                                   for (J_ConversationInbox * conv in inbox.Conversations)
                                                   {
                                                       if ([self conversationByID:conv.ID] == nil)
                                                       {
                                                           Conversation * conversation = [Conversation new];
                                                           conversation.remoteID = conv.ID;
                                                           conversation.author = conv.Sender;
                                                           conversation.date = [conv.Date fromJSONDate];
                                                           conversation.subject = conv.Subject;
                                                           
                                                           [self add:conversation];
                                                       }
                                                       [inboxSet addObject:conv];
                                                   }
                                               }
                                               
                                               if (inboxSet.count > 0)
                                                   [self refreshMessages:inboxSet];
                                           }
                                       }];
        [task resume];
    }
    
    NSURLRequest * outboxRequest = [APIRequest get:@"personalmessage/outbox" withQuery:[NSString stringWithFormat:@"since=%@", sinceDate]];
    if (outboxRequest != nil)
    {
        NSURLSession * session = [NSURLSession sharedSession];
        NSURLSessionDataTask * task = [session dataTaskWithRequest:outboxRequest
                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                       {
                                           if (error != nil)
                                               [CIX reportServerErrors:__PRETTY_FUNCTION__ error:error];
                                           else
                                           {
                                               JSONModelError * jsonError = nil;
                                               NSMutableArray * outboxSet = [NSMutableArray array];
                                               
                                               J_ConversationOutboxSet * outbox = [[J_ConversationOutboxSet alloc] initWithData:data error:&jsonError];
                                               if (jsonError == nil)
                                               {
                                                   for (J_ConversationOutbox * conv in outbox.Conversations)
                                                   {
                                                       if ([self conversationByID:conv.ID] == nil)
                                                       {
                                                           Conversation * conversation = [Conversation new];
                                                           conversation.remoteID = conv.ID;
                                                           conversation.author = conv.Recipient;
                                                           conversation.date = [conv.Date fromJSONDate];
                                                           conversation.subject = conv.Subject;
                                                           
                                                           [self add:conversation];
                                                           
                                                           // Fake an J_ConversationInbox item from the J_ConversationOutbox so that
                                                           // refreshMessages operates on a consistent set of objects.
                                                           J_ConversationInbox * inboxItem = [[J_ConversationInbox alloc] init];
                                                           inboxItem.Date = conv.Date;
                                                           inboxItem.ID = conv.ID;
                                                           inboxItem.Sender = conv.Recipient;
                                                           inboxItem.Subject = conv.Body.firstNonBlankLine;
                                                           inboxItem.Unread = NO;
                                                           [outboxSet addObject:inboxItem];
                                                       }
                                                   }
                                                   self->_lastCheckDate = [NSDate date];
                                               }
                                               
                                               if (outboxSet.count > 0)
                                                   [self refreshMessages:outboxSet];
                                           }
                                       }];
        [task resume];
    }
    _lastCheckDate = [NSDate date];
}

/* Retrieve any new messages in the specified inbox from the message API.
 */
-(void)refreshMessages:(NSArray *)inbox
{
    int unreadCount = 0;
    
    for (J_ConversationInbox * conv in inbox)
    {
        Conversation * conversation = [self conversationByID:conv.ID];
        
        NSString * url = [NSString stringWithFormat:@"personalmessage/%d/message", conversation.remoteID];
        NSURLRequest * messageRequest = [APIRequest get:url];
        
        if (messageRequest != nil)
        {
            NSURLResponse * response;
            NSData * data = [NSURLConnection sendSynchronousRequest:messageRequest returningResponse:&response error:nil];
            if (data != nil)
            {
                JSONModelError * jsonError = nil;
                J_PMessageSet * messages = [[J_PMessageSet alloc] initWithData:data error:&jsonError];
                int newMessages = 0;
                
                NSDate * maxDate = conversation.date;
                
                for (J_PMessage * msg in messages.PMessages)
                    if ([[conversation messages] messageByID:msg.MessageID] == nil)
                    {
                        MailMessage * message = [MailMessage new];
                        message.remoteID = msg.MessageID;
                        message.recipient = msg.Sender;
                        message.date = [msg.Date fromJSONDate];
                        message.body = msg.Body;
                        message.conversationID = conversation.ID;
                        
                        maxDate = [maxDate laterDate:message.date];
                        
                        [[conversation messages] add:message];
                        ++newMessages;
                    }
                
                if (newMessages > 0)
                {
                    conversation.unread = conv.Unread;
                    conversation.deletePending = NO;
                    conversation.readPending = NO;
                    conversation.date = maxDate;
                    [conversation save];
                    
                    unreadCount += newMessages;
                }
            }
        }
    }
    
    if (unreadCount > 0)
        [LogFile.logFile writeLine:@"%d new pmessages retrieved from inbox", unreadCount];
    
    // Notify interested parties
    dispatch_async(dispatch_get_main_queue(),^{
        NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:MAConversationAdded object:nil];
    });
    
    // Separate notification if the unread count changed
    if (unreadCount > 0)
        dispatch_async(dispatch_get_main_queue(),^{
            NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
            [nc postNotificationName:MAConversationChanged object:nil];
        });
}

/** Return the collection of all conversations.
 
 This property returns a ConversationCollection which represents all conversations.
 Refer to the ConversationCollection class for details of how to obtain specific
 conversations and their associated messages.
 
 @return A ConversationCollection object representing all conversations.
 */
-(NSArray *)conversations
{
    if (_conversations == nil)
        _conversations = [[NSMutableArray alloc] initWithArray:[Conversation allRows]];

    return _conversations;
}

/* Initialise ourself.
 */
-(id)initWithArray:(NSArray *)arrayOfConversations
{
    if ((self = [super init]) != nil)
    {
        _conversations = [[NSMutableArray alloc] init];
        for (Conversation * conversation in arrayOfConversations)
            [_conversations addObject:conversation];
    }
    return self;
}

/** Return the conversation with the specified ID.
 
 Returns the conversation whose ID is specified by the conversationID
 parameter.
 
 @param conversationID An unique ID that identifies a conversation
 @return The conversation matching the given ID, or nil if not found.
 */
-(Conversation *)conversationByID:(ID_type)conversationID
{
    for (Conversation * conversation in _conversations)
    {
        if (conversation.remoteID == conversationID)
            return conversation;
    }
    return nil;
}

/* Add the new conversation to the collection
 */
-(void)add:(Conversation *)conversation
{
    [conversation save];
    [_conversations addObject:conversation];
}

/* Remove the specified conversation from the collection.
 */
-(void)remove:(Conversation *)conversation
{
    [conversation delete];
    
    @synchronized(CIX.DBLock) {
        [CIX.DB executeUpdate:@"delete from MailMessage where ConversationID=?"
                withArgumentsInArray:@[ [@(conversation.ID) stringValue] ]];
    }
    [_conversations removeObject:conversation];
}

/* Add the new conversation to the collection with the specified
 * message and notify that the conversation collection was updated.
 */
-(void)add:(Conversation *)conversation withMessage:(MailMessage *)message
{
    if (conversation.remoteID == 0)
        [self add:conversation];
    
    // Add the root message of this conversation.
    [message setConversationID:conversation.ID];
    [[conversation messages] add:message];
    
    // Notify about the change
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:MAConversationAdded object:conversation];
}

/** Return the total number of unread conversations.
 
 This property returns the count of all unread conversations.
 
 @return An NSInteger containing the number of unread conversations.
 */
-(NSInteger)totalUnread
{
    NSInteger count = 0;
    for (Conversation * conversation in _conversations)
        if (conversation.unread)
            ++count;
    return count;
}

/** Return the total number of unread priority conversations.
 
 This property returns the count of all unread priority conversations.
 
 @return An NSInteger containing the number of unread priority conversations.
 */
-(NSInteger)totalUnreadPriority
{
    return 0;
}

/* Return an immutable array of all conversations omitting all
 * deleted messages.
 */
-(NSArray *)allConversations
{
    NSPredicate * pred = [NSPredicate predicateWithFormat:@"deletePending == 0"];
    return [[self conversations] filteredArrayUsingPredicate:pred];
}

/* Support fast enumeration on the conversations list.
 */
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])stackbuf count:(NSUInteger)len
{
    return [_conversations countByEnumeratingWithState:state objects:stackbuf count:len];
}
@end
