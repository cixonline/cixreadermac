//
//  MessageCollection.m
//  CIXClient
//
//  Created by Steve Palmer on 17/10/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "CIX.h"
#import "Message_Private.h"

@implementation MessageCollection

/* Initialise ourself.
 */
-(id)initWithArray:(NSArray *)arrayOfMessages
{
    if ((self = [super init]) != nil)
    {
        _messages = [[NSMutableArray alloc] initWithArray:arrayOfMessages];
        _isOrdered = NO;
    }
    return self;
}

/** Add the message to the collection
 
 If the remoteID is set to 0, the message will be posted to the server on the next
 synchronisation unless postPending is set to NO.
 
 @param message A completed Message to be added
 */
-(void)add:(Message *)message
{
    BOOL isNew = [self addInternal:message];

    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];

    // Run rules on this new message.
    [CIX.ruleCollection applyRules:message];
    
    // If the message was created with the unread flag set, we need
    // to fix the folder counts.
    if (message.unread)
    {
        Folder * folder = message.topic;
        folder.unread += 1;
        if (message.priority)
            folder.unreadPriority += 1;
        [folder setMarkReadRangePending:YES];
        [folder save];
        
        [nc postNotificationName:MAFolderUpdated object:[Response responseWithObject:folder andError:CCResponse_NoError]];
    }
    
    // Save again if pending
    if (message.starPending || message.readPending)
        [message save];

    // Try and post this message if we're pending
    if (message.postPending)
        [message sync];
    
    // Notify about the change
    if (isNew)
        [nc postNotificationName:MAMessageAdded object:message];
    else
        [nc postNotificationName:MAMessageChanged object:[Response responseWithObject:message andError:CCResponse_NoError]];
}

/* Add the specified message to the internal collection.
 */
-(BOOL)addInternal:(Message *)message
{
    BOOL isNew = NO;
    if (message.remoteID == 0)
        message.remoteID = [self getPseudoID];
    if (message.ID > 0)
        [message save];
    else
    {
        [message save];
        [_messages addObject:message];

        // Save any attachments
        for (Attachment * attach in message.attachments)
        {
            attach.messageID = message.ID;
            [attach save];
        }
        
        int lastRemoteID = _messages.count > 0 ? ((Message *)[_messages lastObject]).remoteID : 0;
        _isOrdered = message.remoteID > lastRemoteID;
        _threadedMessages = nil;
        
        isNew = YES;
    }
    return isNew;
}

/** Delete this message from the collection
 
 @param message The message to be deleted
 */
-(void)delete:(Message *)message
{
    if ([_messages containsObject:message])
    {
        [_messages removeObject:message];
        [_threadedMessages removeObject:message];
        [message deleteAttachments];
        [message delete];
        
        // Notify about the deletion
        NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:MAMessageDeleted object:message];
    }
}

/* For Message objects that have no remote ID, compute a pseudo value that is
 * unique in the collection until one is assigned by the server.
 *
 * CIX IDs (remote IDs) run from 1 to some value in the high thousands but almost
 * never beyond that. But this may change in the future. Integers are 32-bit so
 * our approach is to use the top half of the positive range and increase from
 * there.
 *
 * Also note there can be multiple messages in the collection with pseudo IDs.
 */
-(int)getPseudoID
{
    if (_messages.count == 0)
        return INT32_MAX / 2;
    
    int pseudoID = ((Message *)[_messages lastObject]).remoteID + 1;
    return MAX(pseudoID, INT32_MAX / 2);
}

/* Return an array of messages, ordered by increasing remote ID
 */
-(NSArray *)orderedMessages
{
    if (!_isOrdered)
    {
        [_messages sortUsingComparator:^NSComparisonResult(Message * obj1, Message * obj2) {
                        return (obj2.remoteID - obj1.remoteID) == 0 ? NSOrderedSame :
                               (obj2.remoteID < obj1.remoteID) ? NSOrderedDescending :
                                                                NSOrderedAscending;
        }];
        
        // Sanity check
        int lastMessageId = -1;
        for (int i = 0; i < _messages.count; i++)
        {
            Message * message = [_messages objectAtIndex:i];
            if (message.remoteID == lastMessageId)
            {
                [_messages removeObjectAtIndex:i--];
                [message delete];
            }
            lastMessageId = message.remoteID;
        }
        
        _isOrdered = YES;
    }
    return _messages;
}

/** Return the message with the specified ID.
 
 Returns the message whose ID is specified by the messageID
 parameter.
 
 @param messageID An unique ID that identifies a message
 @return The Message matching the given ID, or nil if not found.
 */
-(Message *)messageByID:(ID_type)messageID
{
    for (Message * message in [self orderedMessages])
    {
        if (message.remoteID == messageID)
            return message;
        
        if (!message.isPseudo && message.remoteID > messageID)
            break;
    }
    return nil;
}

/** Return the total number of messages in the collection
 
 @return The number of messages in the collection.
 */
-(NSUInteger)count
{
    return _messages.count;
}

/** Return an NSArray of all messages ordered by conversation
 
 @return An NSArray of messages ordered by conversation
 */
-(NSArray *)allmessagesByConversation
{
    if (_threadedMessages == nil)
    {
        NSUInteger index = 0;
        NSUInteger count = [_messages count];
        
        _threadedMessages = [[NSMutableArray alloc] initWithArray:[self orderedMessages]];
        while (index < count)
        {
            Message * message = _threadedMessages[index];
            message.level = 0;
            message.lastChildMessage = message;
            if (message.commentID > 0)
            {
                NSInteger parentIndex = index - 1;
                while (parentIndex >= 0)
                {
                    Message * parentMessage = _threadedMessages[parentIndex];
                    if (parentMessage.remoteID == message.commentID && parentMessage.topicID == message.topicID)
                    {
                        Message * lastChild = parentMessage.lastChildMessage;
                        
                        while (lastChild != lastChild.lastChildMessage)
                            lastChild = lastChild.lastChildMessage;

                        NSUInteger insertIndex = [_threadedMessages indexOfObject:lastChild] + 1;
                        NSAssert(insertIndex <= index, @"Oops!");
                        if (insertIndex > 0 && insertIndex != index)
                        {
                            [_threadedMessages removeObjectAtIndex:index];
                            [_threadedMessages insertObject:message atIndex:insertIndex];
                        }
                        parentMessage.lastChildMessage = message;
                        message.level = parentMessage.level + 1;
                        break;
                    }
                    --parentIndex;
                }
            }
            ++index;
        }
    }
    return _threadedMessages;
}

/** Return all children of the specified message
 
 Children are all messages which are a direct comment to the
 specified message or a comment to any of its children.
 
 @param message The message for which children should be returned
 @return An NSArray of all child messages
 */
-(NSArray *)childrenOfMessage:(Message *)message
{
    NSArray * conversations = [self allmessagesByConversation];
    NSInteger index = [conversations indexOfObject:message];
    
    NSMutableArray * children = [NSMutableArray array];
    
    while (++index < conversations.count)
    {
        Message * child = conversations[index];
        if (child.level <= message.level)
            break;
        [children addObject:child];
    }
    return children;
}

/** Return all root messages
 
 @return An NSArray of all root messages
 */
-(NSArray *)roots
{
    NSArray * conversations = [self allmessagesByConversation];
    NSMutableArray * roots = [NSMutableArray array];
    
    for (Message * message in conversations)
    {
        if (message.commentID == 0)
            [roots addObject:message];
    }
    return roots;
}

/** Return an NSArray of all messages
 
 @return An NSArray of messages.
 */
-(NSArray *)allMessages
{
    return _messages;
}

/* Support fast enumeration on the messages list.
 */
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])stackbuf count:(NSUInteger)len
{
    return [_messages countByEnumeratingWithState:state objects:stackbuf count:len];
}
@end
