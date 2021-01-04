//
//  Conversation.m
//  CIXClient
//
//  Created by Steve Palmer on 01/09/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "CIX.h"
#import "PMessageReply.h"
#import "PMessageAdd.h"
#import "DateExtensions.h"
#import "StringExtensions.h"

@implementation Conversation

/* Return an empty conversation. The caller must fill out the recipient
 * and subject fields, and add it to the collection.
 */
-(id)init
{
    if ((self = [super init]) != nil)
    {
        self.ID = 0;
        self.remoteID = 0;
        self.date = [NSDate localDate];
    }
    return self;
}

/* Return whether this is a draft conversation. A draft
 * conversation is one which has no remote ID yet and thus
 * has not yet been posted.
 */
-(BOOL)isDraft
{
    return self.remoteID == 0;
}

/* Return the message collection for this conversation.
 */
-(MailCollection *)messages
{
    if (_messages == nil)
    {
        NSString * query = [NSString stringWithFormat:@" where ConversationID=%lld", self.ID];
        _messages = [[MailCollection alloc] initWithArray:[MailMessage allRowsWithQuery:query]];
    }
    return _messages;
}

/* Mark this conversation as read and update
 * in the database.
 */
-(void)markRead
{
    self.unread = NO;
    if (!self.deletePending)
    {
        self.readPending = YES;
        [self save];
    }

    // Notify about the change to the unread count
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:MAConversationChanged object:self];
}

/* Mark this conversation as unread and update
 * in the database.
 */
-(void)markUnread
{
    self.unread = YES;
    if (!self.deletePending)
    {
        self.readPending = YES;
        [self save];
    }
    
    // Notify about the change to the unread count
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:MAConversationChanged object:self];
}

/* Mark this conversation as deleted and update
 * in the database.
 */
-(void)markDelete
{
    if (self.lastError)
        [CIX.conversationCollection remove:self];
    else
    {
        self.unread = NO;
        self.deletePending = YES;
        [self save];
    }
    
    // Notify about the deletion
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:MAConversationDeleted object:self];
}

/** Sync this conversation with the server

 This method scans all messages in the conversation and applies changes to the server. A
 new conversation is posted directly. Replies to the conversation are posted as replies.
 Any change to flags are made on the conversation object.
 */
-(void)sync
{
    if (!CIX.online)
        return;
    
    if (self.deletePending)
        [self deleteConversation];
    
    if (self.readPending)
        [self markReadConversation];
    
    if (self.lastError)
        return;
    
    MailCollection * messages = [self messages];
    __block int conversationID = self.remoteID;
    
    for (MailMessage * message in messages)
        if ([message isDraft])
        {
            if (conversationID > 0)
                [self reply:message];
            else
            {
                J_PMessageAdd * newMessage = [[J_PMessageAdd alloc] init];
                newMessage.Body = [message.body quoteAttributes];
                newMessage.Recipient = message.recipient;
                newMessage.Subject = self.subject;

                NSURLRequest * request = [APIRequest post:@"personalmessage/add" withData:newMessage];
                if (request != nil)
                {
                    NSURLSession * session = [NSURLSession sharedSession];
                    NSURLSessionDataTask * task = [session dataTaskWithRequest:request
                                                             completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                                   {
                                                        Response * resp = [[Response alloc] initWithObject:self];
                
                                                        if (error != nil)
                                                        {
                                                            [CIX reportServerErrors:__PRETTY_FUNCTION__ error:error];
                                                            resp.errorCode = CCResponse_ServerError;
                                                        }
                                                        else
                                                        {
                                                            if (data == nil)
                                                                resp.errorCode = CCResponse_PostFailure;
                                                            else
                                                            {
                                                                NSString * responseString = [APIRequest responseTextFromData:data];
                                                                if (responseString != nil)
                                                                {
                                                                    NSArray * splitStrings = [responseString componentsSeparatedByString:@","];
                                                                    if ([splitStrings count] == 2)
                                                                    {
                                                                        conversationID = [splitStrings[0] intValue];
                                                                        int messageID = [splitStrings[1] intValue];
                                                                        
                                                                        self.remoteID = conversationID;
                                                                        self.date = [[NSDate date] UTCtoGMTBST];
                                                                        [self save];
                                                                        
                                                                        message.remoteID = messageID;
                                                                        [message save];
                                                                        
                                                                        [LogFile.logFile writeLine:@"New message %d in conversation %d posted to server and updated locally", message.remoteID, message.conversationID];
                                                                        
                                                                        return;
                                                                    }
                                                                }
                                                            }
                                                            
                                                            // The message failed to post so mark it as error so we don't retry
                                                            self.lastError = YES;
                                                            [self save];
                                                        }
                                                    }];
                    [task resume];
                }
            }
        }
}

/* Add the specified reply to this conversation and post it to
 * the server.
 */
-(void)reply:(MailMessage *)message
{
    J_PMessageReply * reply = [[J_PMessageReply alloc] init];
    reply.Body = [message.body quoteAttributes];
    reply.ConID = self.remoteID;
    
    NSURLRequest * request = [APIRequest post:@"personalmessage/reply" withData:reply];
    if (request != nil)
    {
        NSURLSession * session = [NSURLSession sharedSession];
        NSURLSessionDataTask * task = [session dataTaskWithRequest:request
                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                       {
                                            if (error != nil)
                                                [CIX reportServerErrors:__PRETTY_FUNCTION__ error:error];
                                            else
                                            {
                                                if (data != nil)
                                                {
                                                    NSString * responseString = [APIRequest responseTextFromData:data];
                                                    if (responseString != nil && [responseString intValue] > 0)
                                                    {
                                                        int messageID = [responseString intValue];
                                                        message.remoteID = messageID;
                                                        message.recipient = CIX.username;
                                                        message.date = [[NSDate date] UTCtoGMTBST];
                                                        [message save];
                                                        
                                                        [LogFile.logFile writeLine:@"Reply %d posted to server and updated locally", message.remoteID];
                                                        
                                                        return;
                                                    }
                                                }
                                            }
                                           
                                           // The reply failed to post so mark it as error so we don't retry
                                           self.lastError = YES;
                                           [self save];
                                       }];
        [task resume];
    }
}

/* Delete the conversation on the server
 */
-(void)deleteConversation
{
    if (CIX.online)
    {
        NSString * inboxUrl = [NSString stringWithFormat:@"personalmessage/inbox/%d/rem", self.remoteID];
        NSURLRequest * inboxRequest = [APIRequest get:inboxUrl];
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
                                                   if (data != nil)
                                                   {
                                                       NSString * responseString = [APIRequest responseTextFromData:data];
                                                       if ([responseString isEqualToString:@"Success"])
                                                       {
                                                           [LogFile.logFile writeLine:@"Conversation %d deleted from inbox", self.remoteID];
                                                           [CIX.conversationCollection remove:self];
                                                       }
                                                   }
                                               }
                                           }];
            [task resume];
        }
        
        NSString * outboxUrl = [NSString stringWithFormat:@"personalmessage/outbox/%d/rem", self.remoteID];
        NSURLRequest * outboxRequest = [APIRequest get:outboxUrl];
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
                                                   if (data != nil)
                                                   {
                                                       NSString * responseString = [APIRequest responseTextFromData:data];
                                                       if ([responseString isEqualToString:@"Success"])
                                                       {
                                                           [LogFile.logFile writeLine:@"Conversation %d deleted from outbox", self.remoteID];
                                                           [CIX.conversationCollection remove:self];
                                                       }
                                                   }
                                               }
                                           }];
            [task resume];
        }
    }
}

/* Mark the conversation as read on the server.
 */
-(void)markReadConversation
{
    if (CIX.online)
    {
        NSString * url = [NSString stringWithFormat:@"personalmessage/%d/%d/toggleread", self.remoteID, self.unread];
        NSURLRequest * request = [APIRequest get:url];
        if (request != nil)
        {
            NSURLSession * session = [NSURLSession sharedSession];
            NSURLSessionDataTask * task = [session dataTaskWithRequest:request
                                                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                           {
                                               if (error != nil)
                                                   [CIX reportServerErrors:__PRETTY_FUNCTION__ error:error];
                                               else
                                               {
                                                   if (data != nil)
                                                   {
                                                       NSString * responseString = [APIRequest responseTextFromData:data];

                                                       // Clear the flags whatever the response.
                                                       self.readPending = NO;
                                                       [self save];
                                                       
                                                       if ([responseString isEqualToString:@"Success"])
                                                           [LogFile.logFile writeLine:@"Conversation %d marked as read on server", self.remoteID];
                                                   }
                                               }
                                           }];
            [task resume];
        }
    }
}

/* Call superclass to get description format
 */
-(NSString *)description
{
    return [super description];
}
@end
