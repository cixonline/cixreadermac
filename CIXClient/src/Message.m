//
//  Message.m
//  CIXClient
//
//  Created by Steve Palmer on 21/10/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "CIX.h"
#import "Message.h"
#import "PostMessage.h"
#import "StarAdd.h"
#import "StringExtensions.h"
#import "DateExtensions.h"
#import "URLSessionExtensions.h"
#import "FMDatabase.h"

@implementation Message

@synthesize topicID = _topicID;

-(void)setLevel:(int)value
{
    _level = value;
}

-(int)level
{
    return _level;
}

-(void)setLastChildMessage:(Message *)value
{
    _lastChildMessage = value;
}

-(Message *)lastChildMessage
{
    return _lastChildMessage;
}

/** Return whether this message has child messages
 
 @return YES if the message has children, NO otherwise.
 */
-(bool)hasChildren
{
    return _lastChildMessage != self;
}

/** Return the count of unread child messages
 
 @return The count of the unread child messages.
 */
-(int)unreadChildren
{
    int unreadCount = 0;
    for (Message * child in [_folder.messages childrenOfMessage:self])
    {
        if (child.unread)
            ++unreadCount;
    }
    return unreadCount;
}

/** Return the root of this message
 
 @return A Message that is the root of this message.
 */
-(Message *)root
{
    Message * message = self;
    while (message.level != 0)
        message = message.parent;
    return message;
}

/** Return the parent of this message

 @return The Message that is the parent of this message if there is one.
 */
-(Message *)parent
{
    return [_folder.messages messageByID:self.commentID];
}

/** Return whether this is a draft message
 
 A draft message is one that is not yet ready to be posted.
 
 @return YES if the message is draft, NO otherwise
 */
-(BOOL)isDraft
{
    return self.isPseudo && !self.postPending;
}

/** Return whether this is a pseudo message
 
 A pseudo message is one that only exists locally and not yet on the
 server and thus has not been assigned a genuine remoteID.
 
 @return YES if the message is pseudo, NO otherwise
 */
-(BOOL)isPseudo
{
    return self.remoteID >= INT32_MAX/2;
}

/** Return whether this message was posted by the authenticated user
 
 @return YES if the message was posted by the user, NO otherwise.
 */
-(BOOL)isMine
{
    return [CIX.username isEqualToString:self.author];
}

/** Return the message subject

 A message's subject is the first non-blank line of the body.
 
 @return The message subject string, which may be empty.
 */
-(NSString *)subject
{
    return [self.body firstNonBlankLine];
}

/** Set the topic ID for this message
 
 @param topicID The ID of the topic to which this message belongs
 */
-(void)setTopicID:(ID_type)topicID
{
    _folder = [CIX.folderCollection folderByID:topicID];
    _topicID = topicID;
}

/** Return the topic ID of this message
 
 @return The ID of the topic to which this message belongs
 */
-(ID_type)topicID
{
    return _topicID;
}

/** Return the topic to which this message belongs
 
 @return The topic folder to which this message belongs
 */
-(Folder*)topic
{
    return _folder;
}

/** Return the forum to which this message belongs
 
 @return The forum folder to which this message belongs
 */
-(Folder*)forum
{
    return _folder.parentFolder;
}

/** Set the star on a message
 */
-(void)addStar
{
    if (!self.starred)
    {
        self.starred = YES;
        self.starPending = YES;
        [self save];
        
        // Notify about the change to the message
        NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:MAMessageChanged object:[Response responseWithObject:self andError:CCResponse_NoError]];
    }
}

/** Remove the star from a message
 */
-(void)removeStar
{
    if (self.starred)
    {
        self.starred = NO;
        self.starPending = YES;
        [self save];
        
        // Notify about the change to the message
        NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:MAMessageChanged object:[Response responseWithObject:self andError:CCResponse_NoError]];
    }
}

/** Set the read lock on the message
 */
-(void)markReadLock
{
    if (!self.readLocked)
    {
        self.readLocked = YES;
        [self innerMarkUnread];
    }
}

/** Clear the read lock on the message
 */
-(void)clearReadLock
{
    if (self.readLocked)
    {
        self.readLocked = NO;
        [self innerMarkRead];
    }
}

/* Mark this message and all child messages as priority
 */
-(void)setPriority
{
    @synchronized(CIX.DBLock) {
        [CIX.DB beginTransaction];
        [self innerSetPriority];
        [CIX.DB commit];
    }
    
    // Notify about the change to the messages by posting a MAFolderChanged
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:MAFolderChanged object:_folder];
}

/* Mark this message and all child messages as priority. Must be
 * called from within a transaction.
 */
-(void)innerSetPriority
{
    BOOL folderChanged = NO;
    self.priority = YES;
    if (self.unread)
    {
        _folder.unreadPriority += 1;
        folderChanged = YES;
    }
    [self save];
    
    NSArray * children = [_folder.messages childrenOfMessage:self];
    for (Message * child in children)
    {
        child.priority = YES;
        if (child.unread)
        {
            _folder.unreadPriority += 1;
            folderChanged = YES;
        }
        [child save];
    }
    if (folderChanged)
    [_folder save];
}

/* Clear the priority on this message
 */
-(void)removePriority
{
    BOOL folderChanged = NO;
    @synchronized(CIX.DBLock) {
        [CIX.DB beginTransaction];
        self.priority = NO;
        if (self.unread)
        {
            _folder.unreadPriority -= 1;
            folderChanged = YES;
        }
        [self save];
        
        NSArray * children = [_folder.messages childrenOfMessage:self];
        for (Message * child in children)
        {
            child.priority = NO;
            if (child.unread)
            {
                _folder.unreadPriority -= 1;
                folderChanged = YES;
            }
            [child save];
        }
        if (folderChanged)
            [_folder save];
        [CIX.DB commit];
    }

    // Notify about the change to the messages by posting a MAFolderChanged
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:MAFolderChanged object:_folder];
}

/* Mark this message and all child messages as ignored.
 */
-(void)setIgnore
{
    int unreadCount = 0;
    @synchronized(CIX.DBLock) {
        
        [CIX.DB beginTransaction];
        unreadCount = [self innerSetIgnored];
        [CIX.DB commit];
    }
    
    // Notify about the update to the folder
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    if (unreadCount > 0)
        [nc postNotificationName:MAFolderUpdated object:[Response responseWithObject:_folder andError:CCResponse_NoError]];
    
    // Notify about the change to the messages by posting a MAFolderChanged
    [nc postNotificationName:MAFolderChanged object:_folder];
}

/* Mark this message and all child messages as ignored and return
 * the count of messages marked unread. Must be called within a
 * transaction.
 */
-(int)innerSetIgnored
{
    int unreadCount = 0;
    bool hasPriority = self.priority;

    self.ignored = YES;
    if (!self.readLocked && self.unread)
    {
        self.unread = NO;
        self.readPending = YES;
        ++unreadCount;
    }
    [self save];
    
    NSArray * children = [_folder.messages childrenOfMessage:self];
    for (Message * child in children)
    {
        child.ignored = YES;
        if (!child.readLocked && child.unread)
        {
            if (child.priority)
                hasPriority = YES;
            child.unread = NO;
            child.readPending = YES;
            ++unreadCount;
        }
        [child save];
    }
    if (_folder.unread >= unreadCount)
    {
        _folder.unread -= unreadCount;
        if (hasPriority && _folder.unreadPriority > 0)
            _folder.unreadPriority -= unreadCount;
        [_folder setMarkReadRangePending:YES];
        [_folder save];
    }
    return unreadCount;
}

/* Clear the ignore on this message and all children.
 */
-(void)removeIgnore
{
    @synchronized(CIX.DBLock) {
        [CIX.DB beginTransaction];
        self.ignored = NO;
        [self save];
        
        NSArray * children = [_folder.messages childrenOfMessage:self];
        for (Message * child in children)
        {
            child.ignored = NO;
            [child save];
        }
        [CIX.DB commit];
    }
    
    // Notify about the change to the messages by posting a MAFolderChanged
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:MAFolderChanged object:_folder];
}

/** Mark this message as read
 
 For efficiency, we always mark the read action as pending for the next sync rather
 than attempt to mark read in real-time. This is a little more fragile if the application
 fails before the next sync but more efficient in terms of network utilisation.
 */
-(void)markRead
{
    if (!self.readLocked)
        [self innerMarkRead];
}

/* Core mark read function shared with read and read-lock logic.
 */
-(void)innerMarkRead
{
    BOOL stateChanged = self.unread;
    if (stateChanged)
    {
        self.unread = NO;
        self.readPending = YES;
    }
    [self save];
    
    // Notify about the change to the message
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:MAMessageChanged object:[Response responseWithObject:self andError:CCResponse_NoError]];

    if (stateChanged)
    {
        if (_folder.unread > 0)
        {
            _folder.unread -= 1;
            if (self.priority && _folder.unreadPriority > 0)
                _folder.unreadPriority -= 1;
            [_folder setMarkReadRangePending:YES];
            [_folder save];
        }
        
        // Notify about the update to the folder
        [nc postNotificationName:MAFolderUpdated object:[Response responseWithObject:_folder andError:CCResponse_NoError]];
    }
}

/** Mark all messages from this thread down as read.
 */
-(void)markReadThread
{
    @synchronized(CIX.DBLock) {
        int countMarkedRead = 0;
        int countPriorityMarkedRead = 0;
        
        [CIX.DB beginTransaction];
        if (!self.readLocked && self.unread)
        {
            self.unread = NO;
            self.readPending = YES;
            if (self.priority)
                ++countPriorityMarkedRead;
            ++countMarkedRead;
            [self save];
        }
        
        NSArray * children = [_folder.messages childrenOfMessage:self];
        for (Message * child in children)
        {
            if (!child.readLocked && child.unread)
            {
                child.unread = NO;
                child.readPending = YES;
                if (child.priority)
                    ++countPriorityMarkedRead;
                ++countMarkedRead;
                [child save];
            }
        }
        if (countMarkedRead > 0)
        {
            _folder.unread -= countMarkedRead;
            _folder.unreadPriority -= countPriorityMarkedRead;
            [_folder setMarkReadRangePending:YES];
            [_folder save];
        }
        [CIX.DB commit];
    }
    
    // Notify about the change to the messages by posting a MAFolderChanged
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:MAFolderChanged object:_folder];
}

/** Mark all messages from this thread down as unread.
 */
-(void)markUnreadThread
{
    @synchronized(CIX.DBLock) {
        int countMarkedUnread = 0;
        int countPriorityMarkedUnread = 0;
        
        [CIX.DB beginTransaction];
        if (!self.readLocked && !self.unread)
        {
            self.unread = YES;
            self.readPending = YES;
            if (self.priority)
                ++countPriorityMarkedUnread;
            ++countMarkedUnread;
            [self save];
        }
        
        NSArray * children = [_folder.messages childrenOfMessage:self];
        for (Message * child in children)
        {
            if (!child.readLocked && !child.unread)
            {
                child.unread = YES;
                child.readPending = YES;
                if (child.priority)
                    ++countPriorityMarkedUnread;
                ++countMarkedUnread;
                [child save];
            }
        }
        if (countMarkedUnread > 0)
        {
            _folder.unread += countMarkedUnread;
            _folder.unreadPriority += countPriorityMarkedUnread;
            [_folder setMarkReadRangePending:YES];
            [_folder save];
        }
        [CIX.DB commit];
    }
    
    // Notify about the change to the messages by posting a MAFolderChanged
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:MAFolderChanged object:_folder];
}

/** Mark this message as unread
 
 For efficiency, we always mark the unread action as pending for the next sync rather
 than attempt to mark unread in real-time. This is a little more fragile if the application
 fails before the next sync but more efficient in terms of network utilisation.
 */
-(void)markUnread
{
    if (!self.readLocked)
        [self innerMarkUnread];
}

/* Core mark unread function shared with read and read-lock logic.
 */
-(void)innerMarkUnread
{
    BOOL stateChanged = !self.unread;
    if (stateChanged)
    {
        self.unread = YES;
        self.readPending = YES;
    }
    [self save];

    // Notify about the change to the message
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:MAMessageChanged object:[Response responseWithObject:self andError:CCResponse_NoError]];

    if (stateChanged)
    {
        _folder.unread += 1;
        if (self.priority)
            _folder.unreadPriority += 1;
        [_folder setMarkReadRangePending:YES];
        [_folder save];
        
        // Notify about the update to the folder
        [nc postNotificationName:MAFolderUpdated object:[Response responseWithObject:_folder andError:CCResponse_NoError]];
    }
}

/** Withdraw this message from the server.
 */
-(void)withdraw
{
    [self withdrawMessage];
}

/** Sync this message with the server
 
 This method updates the server copy of the message with any local changes. If the
 message is new, it posts it to the server if possible.
 */
-(void)sync
{
    if (!CIX.online)
        return;
    
    if (self.postPending)
        [self postMessage];
    
    if (self.starPending)
        [self starMessage];
    
    if (self.withdrawPending)
        [self withdrawMessage];
}

/* Post this message to the server
 */
-(void)postMessage
{
    J_PostMessage * message = [[J_PostMessage alloc] init];
    message.Body = self.body;
    message.Forum = _folder.parentFolder.name;
    message.Topic = _folder.name;
    message.MsgID = self.commentID;
    message.MarkRead = !self.unread;
    
    self.postPending = NO;
    
    NSURLRequest * request = [APIRequest post:@"forums/post" withData:message];
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
                                                       int messageID = [responseString intValue];
                                                       if (messageID <= 0)
                                                       {
                                                           resp.errorCode = CCResponse_PostFailure;
                                                           self.postPending = YES;
                                                       }
                                                       else
                                                       {
                                                           /* Handle potential race condition where we post a message but the message
                                                            * is retrieved via a sync before the response to forums/post. In this case
                                                            * just delete this copy of the message.
                                                            */
                                                           if ([_folder.messages messageByID:messageID] != nil)
                                                           {
                                                               [_folder.messages delete:self];
                                                               return;
                                                           }
                                                           self.remoteID = messageID;
                                                           self.postPending = NO;
                                                           self.date = [[NSDate date] UTCtoGMTBST];
                                                           [self save];
                                                           
                                                           if (self.commentID == 0)
                                                               [LogFile.logFile writeLine:@"Posted new thread \"%@\" as message %d", self.body.firstNonBlankLine, self.remoteID];
                                                           else
                                                               [LogFile.logFile writeLine:@"Posted reply to message %d as message %d", self.commentID, self.remoteID];
                                                       }
                                                   }
                                               }
                                           }
                                           
                                           dispatch_async(dispatch_get_main_queue(),^{
                                               NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
                                               [nc postNotificationName:MAMessageChanged object:resp];
                                           });
                                       }];
        [task resume];
    }
}

/* Set or remove the star on a message on the server.
 */
-(void)starMessage
{
    LogFile * logFile = [LogFile logFile];
    if (self.starred)
    {
        J_StarAdd * starAdd = [J_StarAdd new];
        starAdd.Forum = _folder.parentFolder.name;
        starAdd.Topic = _folder.name;
        starAdd.MsgID = self.remoteID;

        [logFile writeLine:@"Adding star to message %d in %@/%@", starAdd.MsgID, starAdd.Forum, starAdd.Topic];
        
        NSURLRequest * request = [APIRequest post:@"starred/add" withData:starAdd];
        if (request != nil)
        {
            NSURLResponse *response;
            NSError *error;
            
            NSData * data = [NSURLSession sendSynchronousDataTaskWithRequest:request returningResponse:&response error:&error];
            if (error != nil)
               [CIX reportServerErrors:__PRETTY_FUNCTION__ error:error];
            else
            {
               if (data != nil)
               {
                   NSString * responseString = [APIRequest responseTextFromData:data];
                   if ([responseString isEqualToString:@"Success"])
                   {
                       [logFile writeLine:@"Star successfully added"];
                       self.starPending = NO;
                       [self save];
                   }
               }
            }
        }
    }
    else
    {
        [logFile writeLine:@"Removing star from message %d in %@/%@", self.remoteID, _folder.parentFolder.name, _folder.name];
        
        NSString * url = [NSString stringWithFormat:@"starred/%@/%@/%d/rem", _folder.parentFolder.name, _folder.name, self.remoteID];
        NSURLRequest * request = [APIRequest get:url];
        NSURLResponse *response;
        NSError *error;
        
        NSData * data = [NSURLSession sendSynchronousDataTaskWithRequest:request returningResponse:&response error:&error];
        if (error != nil)
           [CIX reportServerErrors:__PRETTY_FUNCTION__ error:error];
        else
        {
           if (data != nil)
           {
               NSString * responseString = [APIRequest responseTextFromData:data];
               if ([responseString isEqualToString:@"Success"])
                   [logFile writeLine:@"Star successfully removed"];

               self.starPending = NO;
               [self save];
           }
        }
    }
}

/* Withdraw a message from the server.
 */
-(void)withdrawMessage
{
    if (!CIX.online)
    {
        self.withdrawPending = YES;
        [self save];
        return;
    }
    
    LogFile * logFile = [LogFile logFile];
    [logFile writeLine:@"Withdrawing message %d from %@/%@", self.remoteID, _folder.parentFolder.name, _folder.name];

    NSString * url = [NSString stringWithFormat:@"forums/%@/%@/%d/withdraw", _folder.parentFolder.name, _folder.name, self.remoteID];
    NSURLRequest * request = [APIRequest get:url];
    NSURLResponse *response;
    NSError *error;
    
    NSData * data = [NSURLSession sendSynchronousDataTaskWithRequest:request returningResponse:&response error:&error];
    if (error != nil)
        [CIX reportServerErrors:__PRETTY_FUNCTION__ error:error];
    else
    {
        if (data != nil)
        {
            NSString * responseString = [APIRequest responseTextFromData:data];
            if ([responseString isEqualToString:@"Success"])
            {
                [logFile writeLine:@"Message successfully withdrawn"];
                self.withdrawPending = NO;
                
                // Replace the local text to avoid round-tripping to the server
                // to get a copy of the withdrawn message with the appropriate replacement
                // text.
                if (self.isMine)
                    self.body = NSLocalizedString(@"Message withdrawn by Author", nil);
                else
                    self.body = NSLocalizedString(@"Message withdrawn by Moderator", nil);
                [self save];

                Response * resp = [[Response alloc] initWithObject:self];
                resp.object = self;

                dispatch_async(dispatch_get_main_queue(),^{
                    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
                    [nc postNotificationName:MAMessageChanged object:resp];
                });
            }
        }
    }
}

/** Return the body of the message as a quoted string

 @return An NSString containing the message body with each line quoted
 */
-(NSString *)quotedBody
{
    return self.body.quotedString;
}

/* Call superclass to get description format
 */
-(NSString *)description
{
    return [super description];
}
@end
