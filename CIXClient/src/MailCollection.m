//
//  MailCollection.m
//  CIXClient
//
//  Created by Steve Palmer on 02/09/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "CIX.h"

@implementation MailCollection

/* Initialise ourself.
 */
-(id)initWithArray:(NSArray *)arrayOfMessages
{
    if ((self = [super init]) != nil)
    {
        _messages = [[NSMutableArray alloc] init];
        for (MailMessage * message in arrayOfMessages)
            [_messages addObject:message];
    }
    return self;
}

/* Add the specified message to the collection.
 */
-(void)add:(MailMessage *)newMessage
{
    [newMessage save];
    [_messages addObject:newMessage];
}

/** Return the message with the specified ID.
 
 Returns the message whose ID is specified by the messageID
 parameter.
 
 @param messageID An unique ID that identifies a message
 @return The message matching the given ID, or nil if not found.
 */
-(MailMessage *)messageByID:(ID_type)messageID
{
    for (MailMessage * message in _messages)
    {
        if (message.remoteID == messageID)
            return message;
    }
    return nil;
}

/** Return an immutable array of all messages
 
 @return An NSArray of MailMessage objects.
 */
-(NSArray *)allMessages
{
    return _messages;
}

/* Return the count of messages in the collection.
 */
-(NSInteger)count
{
    return [_messages count];
}

/* Support fast enumeration on the conversations list.
 */
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])stackbuf count:(NSUInteger)len
{
    return [_messages countByEnumeratingWithState:state objects:stackbuf count:len];
}
@end
