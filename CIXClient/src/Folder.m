//
//  Folder.m
//  CIXClient
//
//  Created by Steve Palmer on 31/07/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "CIX.h"
#import "FMDatabase.h"
#import "Message_Private.h"
#import "MessageResultSet.h"
#import "Range.h"
#import "StringExtensions.h"
#import "DateExtensions.h"
#import "URLSessionExtensions.h"

@implementation Folder

-(id)init
{
    if ((self = [super init]) != nil)
        _children = [NSMutableArray array];
    return self;
}

/** Return the parent folder

 @return The parent Folder object, or nil if this folder has no parent
 */
-(Folder *)parentFolder
{
    return [CIX.folderCollection folderByID:self.parentID];
}

/** Return the array of all child folders
 
 @return An NSArray of all child folders, or nil if this folder has no children.
 */
-(NSArray *)children
{
    return _children;
}

/** Return a child folder by name

 This method searches the children of this folder for one whose name matches
 the given name.
 
 @param name The name of the child folder
 @return The Folder for the child whose name matches, or nil
 */
-(Folder *)childByName:(NSString *)name
{
    for (Folder * child in _children)
    {
        if ([child.name isEqualToString:name])
            return child;
    }
    return nil;
}

/** Add this folder as a child folder
 
 The new folder will be inserted into the collection in alphanumerical order
 of its siblings if treeIndex is 0, or it will be inserted in treeIndex order
 if the value is non-zero. If the process of adding the folder causes the
 treeIndex of the sibilings to be renumbered then all subsequent sibling
 folders are updated in the database.
 
 @param folder folder to add as a child folder
 */
-(void)add:(Folder *)folder
{
    int index;
    
    if (folder.treeIndex == 0)
    {
        int lastTreeIndex = 0;
        int nextTreeIndex = 200;

        // If no pre-specified position in the list then insert this
        // folder is alphabetical order.
        for (index = 0; index < _children.count; ++index)
        {
            Folder * sibling = _children[index];
            nextTreeIndex = sibling.treeIndex;
            if ([folder compare:sibling] == NSOrderedAscending)
                break;
            lastTreeIndex = sibling.treeIndex;
            nextTreeIndex = sibling.treeIndex + 100;
        }
        
        folder.treeIndex = lastTreeIndex + (nextTreeIndex - lastTreeIndex) / 2;
        [_children insertObject:folder atIndex:index];
    }
    else
    {
        // Otherwise insert it in treeIndex order.
        for (index = 0; index < _children.count; ++index)
        {
            Folder * sibling = _children[index];
            if (sibling.treeIndex >= folder.treeIndex)
                break;
        }
        [_children insertObject:folder atIndex:index];
    }
    [self reindex];
}

/** Reindex the child folders, updating their treeIndex position
 
 Call this function after modifying the treeIndex for any child
 folders.
 */
-(void)reindex
{
    int lastTreeIndex = 0;
    for (Folder * child in _children)
    {
        if (child.treeIndex == 0 || child.treeIndex <= lastTreeIndex)
        {
            child.treeIndex = lastTreeIndex + 100;
            [child save];
        }
        lastTreeIndex = child.treeIndex;
    }
}

/** Remove the specified folder from the child collection
 
 The specified folder is removed from the collection of child folders
 of this folder if it is present. No error occurs if it was not
 originally present before removal.
 
 @param folder The Folder to remove
 */
-(void)remove:(Folder *)folder
{
    [_children removeObject:folder];
}

/** Move this folder to before the specified folder
 
 This method moves the current folder to before the specified folder in
 the parent's folder list. Both the current folder and priorFolder are
 assumed to both have the same parent otherwise this function does
 nothing.

 @param folder The folder to move
 @param nextFolder The folder before which to place this folder
 */
-(void)move:(Folder *)folder toBefore:(Folder *)nextFolder
{
    if ([_children containsObject:folder])
    {
        [_children removeObject:folder];

        NSInteger index = (nextFolder == nil) ? _children.count : [_children indexOfObject:nextFolder];
        if (index != NSNotFound)
        {
            [_children insertObject:folder atIndex:index];

            // Force this folder to get a new treeIndex value
            folder.treeIndex = 0;
            [self reindex];
        }
    }
}

/** Move this folder to after the specified folder
 
 This method moves the current folder to after the specified folder in
 the parent's folder list. Both the current folder and priorFolder are
 assumed to both have the same parent otherwise this function does
 nothing.
 
 @param folder The folder to move
 @param nextFolder The folder after which to place this folder
 */
-(void)move:(Folder *)folder toAfter:(Folder *)nextFolder
{
    if ([_children containsObject:folder])
    {
        [_children removeObject:folder];
        
        NSInteger index = (nextFolder == nil) ? _children.count-1 : [_children indexOfObject:nextFolder];
        if (index != NSNotFound)
        {
            [_children insertObject:folder atIndex:index+1];
            
            // Force this folder to get a new treeIndex value
            folder.treeIndex = 0;
            [self reindex];
        }
    }
}

/** Return whether this is a recent folder.
 
 @return YES if this is a recent folder, NO otherwise.
 */
-(BOOL)isRecent
{
    return (self.flags & FolderFlagsRecent) == FolderFlagsRecent;
}

/** Return whether this forum has been resigned.
 
 @return YES if the forum is resigned, NO otherwise.
 */
-(BOOL)isResigned
{
    return (self.flags & FolderFlagsResigned) == FolderFlagsResigned;
}

/** Return whether this forum can be resigned.
 
 @return YES if the forum can be resigned, NO otherwise.
 */
-(BOOL)canResign
{
    return (self.flags & FolderFlagsCannotResign) == 0;
}

/** Return whether this folder needs to be refreshed
 
 @return YES if the folder needs a refresh from the server.
 */
-(BOOL)refreshRequired
{
    return _refreshRequired;
}

/* Returns the result of comparing two folders by folder name.
 */
-(NSComparisonResult)compare:(Folder *)otherObject
{
    return [self.name compare:otherObject.name options:NSNumericSearch];
}

/** Return the number of messages in this folder
 
 @return An integer count of messages in the folder.
 */
-(NSInteger)countOfMessages
{
    if (_messages != nil)
        return [_messages count];

    // Folder not loaded but we just want the count. So don't page them in unnecessarily
    NSString * filter = [NSString stringWithFormat:@" where TopicID=%lld", self.ID];
    return [Message countRowsWithQuery:filter];
}

/** Return all the messages in this folder.
 
 @return An NSArray of Message objects.
 */
-(MessageCollection *)messages
{
    if (_messages == nil)
    {
        NSString * filter = [NSString stringWithFormat:@" where TopicID=%lld", self.ID];
        _messages = [[MessageCollection alloc] initWithArray:[Message allRowsWithQuery:filter]];
        
        // Fix up folder count mismatches
        int totalUnread = 0;
        int totalUnreadPriority = 0;
        
        for (Message * message in _messages.orderedMessages)
        {
            if (message.unread)
            {
                ++totalUnread;
                if (message.priority)
                    ++totalUnreadPriority;
            }
        }
        if (self.unread != totalUnread || self.unreadPriority != totalUnreadPriority)
        {
            self.unread = totalUnread;
            self.unreadPriority = totalUnreadPriority;
            [self save];
        }
    }
    return _messages;
}

/** Do a fixup on the folder, checking for gaps
 
 Any gaps found will trigger a retrieve to the server to obtain the missing messages
 and restore them.
 */
-(void)fixup
{
    NSMutableIndexSet * mutableIndexSet = [[NSMutableIndexSet alloc] init];
    int lastMessageId = 0;
    
    for (Message * message in _messages.orderedMessages)
    {
        if (!message.isPseudo && message.remoteID != lastMessageId + 1)
        {
            while (++lastMessageId < message.remoteID)
                [mutableIndexSet addIndex:lastMessageId];
        }
        lastMessageId = message.remoteID;
    }
    if (mutableIndexSet.count > 0)
    {
        NSMutableArray * array = [NSMutableArray new];
        [mutableIndexSet enumerateRangesUsingBlock:^(NSRange indexRange, BOOL * stop) {
            J_Range * range = [J_Range new];
            range.ForumName = self.parentFolder.name;
            range.TopicName = self.name;
            range.Start = (int)indexRange.location;
            range.End = ((int)indexRange.location + (int)indexRange.length) - 1;
            [array addObject:range];
        }];

        NSURLRequest * request = [APIRequest post:@"forums/messagerange" withData:array];
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
                                                   JSONModelError * jsonError = nil;
                                                   
                                                   J_MessageResultSet2 * msgs = [[J_MessageResultSet2 alloc] initWithData:data error:&jsonError];
                                                   if (jsonError != nil)
                                                       resp.errorCode = CCResponse_NoSuchForum;
                                                   else
                                                       [self addMessages:msgs.Messages];
                                               }
                                               
                                               // Notify interested parties that the folder has changed
                                               dispatch_async(dispatch_get_main_queue(),^{
                                                   NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
                                                   [nc postNotificationName:MAFolderFixed object:resp];
                                               });
                                           }];
            [task resume];
        }
    }
}

/** Return a message from the cache
 
 Given a message that has been obtained from the database directly, this method checks
 whether the same message has been cached by the folder and, if so, returns the cached
 copy. Otherwise it returns the original message.
 
 @param message The message whose copy is to be retrieved from the cache
 @return A copy of the specified message from the cache
 */
-(Message *)getCachedMessage:(Message *)message
{
    return (_messages != nil) ? [self.messages messageByID:message.remoteID] : message;
}

/* Return the encoded name of this folder for use by API functions where
 * the '.' character causes issues with IIS URL parsing. The API server will
 * restore the correct character before processing.
 */
-(NSString *)encodedName
{
    return [self.name stringByReplacingOccurrencesOfString:@"." withString:@"~"];
}

/* Resign this folder.
 */
-(void)resign
{
    if ([self canResign])
        [self resignFolder];
}

/** Return whether there are any pending actions on this folder.
 
 Pending actions are any actions initiated offline which require access to the server
 to complete.
 
 @return YES if this folder has pending actions. NO otherwise.
 */
-(BOOL)hasPending
{
    return self.resignPending || self.markReadRangePending;
}

/* Sync this Folder object with the server based on what is
 * pending synchronisation.
 */
-(void)sync
{
    if (self.resignPending)
        [self resignFolder];
    
    [self markReadRange];
    [self markUnreadRange];
}

/* Perform shut-down sync. All actions here must be run
 * synchronously.
 */
-(void)closeSync
{
    [self markReadRange];
    [self markUnreadRange];
}

/** Refresh this folder from the server
 
 Call this method to refresh the folder from the server and retrieve any new
 messages posted since the last refresh.
 
 On completion, a MAFolderRefreshed notification is posted with a Response object where
 the object field is set to the folder and the errorCode field is set to
 the appropriate error code:
 
 * CCResponse_NoError - the folder was successfully refreshed
 * CCResponse_ServerError - a generic error occurred
 * CCResponse_Offline - the server is offline
 * CCResponse_Busy - an existing refresh is in progress
 */
-(void)refresh
{
    if (!CIX.online)
    {
        NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:MAFolderRefreshed object:[Response responseWithObject:self andError:CCResponse_Offline]];
        return;
    }
    
    if (_isFolderRefreshing)
    {
        NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:MAFolderRefreshed object:[Response responseWithObject:self andError:CCResponse_Busy]];
        return;
    }

    NSString * url = [NSString stringWithFormat:@"forums/%@/%@/allmessages", self.parentFolder.encodedName, self.name];

    // Get all new messages since the most recent in the folder or, if the folder
    // is empty, get everything back to the first one.
    NSDate * sinceDate = [NSDate dateWithTimeIntervalSince1970:0];
    if (self.messages.count > 0)
        sinceDate = [[NSDate date] dateByAddingTimeInterval:-30*24*60*60]; // Last 30 days

    _isFolderRefreshing = YES;
    NSURLRequest * request = [APIRequest get:url withQuery:[NSString stringWithFormat:@"maxresults=5000&since=%@", [CIX.dateFormatter stringFromDate:sinceDate]]];
    if (request != nil)
    {
        // Since this is an intensive process, we need to notify ahead of time to give UI the
        // chance to show the appropriate progress feedback.
        dispatch_async(dispatch_get_main_queue(),^{
            NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
            [nc postNotificationName:MAFolderRefreshStarted object:self];
        });

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
                                               JSONModelError * jsonError = nil;
                                               
                                               J_MessageResultSet2 * msgs = [[J_MessageResultSet2 alloc] initWithData:data error:&jsonError];
                                               if (jsonError != nil)
                                                   resp.errorCode = CCResponse_NoSuchForum;
                                               else
                                                   [self addMessages:msgs.Messages];
                                           }

                                           // Notify interested parties that the folder has changed
                                           dispatch_async(dispatch_get_main_queue(),^{
                                               NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
                                               [nc postNotificationName:MAFolderRefreshed object:resp];
                                           });
                                           
                                           _isFolderRefreshing = NO;
                                       }];
        [task resume];
    }
}

-(void)addMessages:(NSArray *)messages
{
    int previousUnread = self.unread;
    int countOfNewMessages = 0;
    
    @synchronized(CIX.DBLock) {
        [CIX.DB beginTransaction];
        
        for (J_Message2 * msg in messages)
        {
            Message * message = [self.messages messageByID:msg.ID];
            if (message == nil)
            {
                message = [Message new];
                message.remoteID = msg.ID;
                message.author = msg.Author;
                message.body = msg.Body;
                message.date = [CIX.CIXDateFormatter dateFromString:msg.DateTime];
                message.commentID = msg.ReplyTo;
                message.rootID = msg.RootID;
                message.topicID = self.ID;
                message.starred = msg.Starred;
                message.priority = msg.Priority;
                message.unread = msg.Unread;
                
                [CIX.ruleCollection applyRules:message];
                
                [self.messages addInternal:message];
                
                if (message.unread)
                {
                    ++self.unread;
                    if (message.priority)
                        ++self.unreadPriority;
                }
                if (message.ignored)
                {
                    NSArray * children = [self.messages childrenOfMessage:message];
                    for (Message * child in children)
                        if (![child ignored])
                            [child innerSetIgnored];
                }
                if (message.priority)
                {
                    NSArray * children = [self.messages childrenOfMessage:message];
                    for (Message * child in children)
                        if (![child priority])
                            [child innerSetPriority];
                }
                ++countOfNewMessages;
            }
            else
            {
                BOOL oldState = message.unread;
                
                if (!message.readPending)
                    message.unread = msg.Unread;
                message.starred = msg.Starred;
                
                if (oldState != message.unread && !message.readLocked)
                {
                    self.unread += message.unread ? 1 : -1;
                    if (message.priority)
                        self.unreadPriority += message.unread ? 1 : -1;
                }
                
                message.body = msg.Body;
                message.date = [CIX.CIXDateFormatter dateFromString:msg.DateTime];
                [message save];
            }
        }
        if (previousUnread != self.unread)
            [self save];
        
        [CIX.DB commit];
    }
    
    // Don't need to refresh this any more
    _refreshRequired = NO;
    
    if (countOfNewMessages > 0)
        [LogFile.logFile writeLine:@"%@/%@ refreshed with %d new messages", self.parentFolder.name, self.name, countOfNewMessages];
}

/* Resign this folder
 *
 * This method issues the appropriate API request to resign the authenticated user
 * from this forum or topic on the server. The resign request occurs asynchronously and a
 * MAForumResigned notification is posted on completion of the resign.
 */
-(void)resignFolder
{
    if (!CIX.online)
    {
        NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:MAForumResigned object:[Response responseWithObject:self andError:CCResponse_Offline]];
        
        self.resignPending = YES;
        [self save];
        return;
    }
    
    Folder * parent = [self parentFolder];
    
    NSString * url = IsTopLevelFolder(self) ?
            [NSString stringWithFormat:@"forums/%@/resign", self.encodedName] :
            [NSString stringWithFormat:@"forums/%@/%@/resigntopic", parent.encodedName, self.encodedName];

    NSURLRequest * request = [APIRequest get:url];
    if (request != nil)
    {
        LogFile * log = LogFile.logFile;
        [log writeLine:@"Resigning from %@", self.name];
        
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
                                                   resp.errorCode = CCResponse_ResignFailure_Limited;
                                               else
                                               {
                                                   NSString * responseString = [APIRequest responseTextFromData:data];
                                                   if (responseString != nil)
                                                   {
                                                       if (![responseString isEqualToString:@"Success"])
                                                           resp.errorCode = CCResponse_ResignFailure_NoSuchForum;
                                                       else
                                                           [log writeLine:@"Successfully resigned from %@", self.name];
                                                       
                                                       if (self.deletePending)
                                                       {
                                                           dispatch_async(dispatch_get_main_queue(),^{
                                                               self.deletePending = NO;
                                                               [self delete:NO];
                                                               return;
                                                           });
                                                       }
                                                       
                                                       self.resignPending = NO;
                                                       self.flags |= FolderFlagsResigned;
                                                       
                                                       [self save];
                                                   }
                                               }
                                           }
                                           
                                           // Alert interested parties about the result of the resign
                                           dispatch_async(dispatch_get_main_queue(),^{
                                               NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
                                               [nc postNotificationName:MAForumResigned object:resp];
                                           });
                                       }];
        [task resume];
    }
}

/* Mark a range of messages read
 */
-(void)markReadRange
{
    [self markReadRange:@"read"];
}

/* Mark a range of messages unread
 */
-(void)markUnreadRange
{
    [self markReadRange:@"unread"];
}

/* Mark a range of messages read or unread
 *
 * This method efficiently issues a markreadrange against all messages that have been marked
 * as read or unread.
 *
 * NOTE: this must run synchronously as it is called during shutdown.
 */
-(void)markReadRange:(NSString *)rangeType
{
    if (!CIX.online)
        return;
    
    BOOL markAsRead = [rangeType isEqualToString:@"read"];
    NSMutableIndexSet * mutableIndexSet = [[NSMutableIndexSet alloc] init];
    for (Message * message in self.messages)
    {
        if (message.readPending && message.unread != markAsRead)
            [mutableIndexSet addIndex:message.remoteID];
    }
    if (mutableIndexSet.count == 0)
    {
        self.markReadRangePending = false;
        [self save];
        return;
    }
    
    // Create a set of range items for each group of consecutive message IDs. Thus if
    // messages 340, 341, 342, 344, 345, 348 were all marked read then this would create
    // three Range objects: 340-342, 344-345 and 348.
    //
    NSMutableArray * array = [NSMutableArray new];
    [mutableIndexSet enumerateRangesUsingBlock:^(NSRange indexRange, BOOL * stop) {
        J_Range * range = [J_Range new];
        range.ForumName = self.parentFolder.name;
        range.TopicName = self.name;
        range.Start = (int)indexRange.location;
        range.End = ((int)indexRange.location + (int)indexRange.length) - 1;
        [array addObject:range];
    }];
    
    self.markReadRangePending = false;
    
    NSString * url = [NSString stringWithFormat:@"forums/%@/markreadrange", BoolToString(markAsRead)];
    NSURLRequest * request = [APIRequest post:url withData:array];
    if (request != nil)
    {
        NSURLResponse * response;
        NSError * error;
        
        NSData * data = [NSURLSession sendSynchronousDataTaskWithRequest:request returningResponse:&response error:&error];
        if (error != nil)
            [CIX reportServerErrors:__PRETTY_FUNCTION__ error:error];
        else
        {
            if (data != nil)
            {
                NSString * responseString = [APIRequest responseTextFromData:data];
                if (responseString != nil && [responseString isEqualToString:@"Success"])
                {
                    __block int readCount = 0;
                   
                    // Iterate over the original indexset because we need to exclude messages whose
                    // readPending flag were set after we created the original indexset.
                    @synchronized(CIX.DBLock) {
                        [CIX.DB beginTransaction];
                        [mutableIndexSet enumerateIndexesUsingBlock:^(NSUInteger remoteID, BOOL * stop) {
                            Message * message = [self.messages messageByID:remoteID];
                            message.readPending = NO;
                            [message save];
                            ++readCount;
                        }];
                       
                        // If we cleared the flag and no new pending read actions arrived
                        // since, persist the flag to the DB.
                        if (!self.markReadRangePending)
                            [self save];
                       
                        [CIX.DB commit];
                    }
                    LogFile * log = LogFile.logFile;
                    [log writeLine:@"Marked %d messages %@ in %@/%@", readCount, rangeType, self.parentFolder.name, self.name];
                }
            }
        }
    }
}

/* Mark this folder as deleted and update
 * in the database.
 */
-(void)delete:(BOOL)resign
{
    if (resign && self.canResign)
    {
        self.deletePending = YES;
        [self save];
        [self resign];
        return;
    }
    
    @synchronized(CIX.DBLock) {
        [CIX.DB beginTransaction];
        
        // We need to copy the child array because removing each child
        // also modifies the collection.
        NSArray * children = [NSArray arrayWithArray:self.children];
        for (Folder * child in children)
            [child internalDelete];
        
        [self internalDelete];
        
        [CIX.DB commit];
    }
    
    // Force a full sync if we delete a folder
    [CIX setLastSyncDate:[NSDate defaultDate]];

    [LogFile.logFile writeLine:@"Folder %@ deleted", self.displayName];
    
    // Notify about the deletion
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:MAFolderDeleted object:self];
}

/* Internal delete procedure to remove a folder from the database and
 * the internal data structures.
 */
-(void)internalDelete
{
    // Delete messages
    [CIX.DB executeUpdate:@"delete from Message where TopicID=?"
     withArgumentsInArray:@[ [@(self.ID) stringValue] ]];
    
    // Actually remove ourselves from the database
    [super delete];
    
    [CIX.folderCollection remove:self];
}

/** Mark all messages read in this folder.
 
 We cannot use the markfolderread API for this because the folder may contain
 read-locked messages. Instead we need to mark read a range.
 */
-(void)markAllRead
{
    NSThread * myThread = [[NSThread alloc] initWithTarget:self selector:@selector(markAllReadOnThread:) object:nil];
    [myThread start];
}

/* Run a mark all read on this folder within a thread.
 */
-(void)markAllReadOnThread:(id)sender
{
    NSMutableArray * foldersUpdated = [NSMutableArray array];
    @synchronized(CIX.DBLock) {
        [CIX.DB beginTransaction];
        
        NSArray * children = [NSArray arrayWithArray:self.children];
        for (Folder * child in children)
        {
            if ([child internalMarkAllRead])
                [foldersUpdated addObject:child];
        }
        
        if ([self internalMarkAllRead])
            [foldersUpdated addObject:self];

        [CIX.DB commit];
    }

    // Notify about the change to the folders
    dispatch_async(dispatch_get_main_queue(),^{
        NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
        for (Folder * folder in foldersUpdated)
            [nc postNotificationName:MAFolderRefreshed object:[Response responseWithObject:folder andError:CCResponse_NoError]];
    });
}

/* Internal mark read procedure to mark all messages in this folder
 * as read.
 */
-(int)internalMarkAllRead
{
    NSArray * messages = [NSArray arrayWithArray:self.messages.allMessages];
    int countMarkedRead = 0;
    for (Message * message in messages)
    {
        if (message.unread && !message.readLocked)
        {
            message.unread = NO;
            if (message.priority)
                --self.unreadPriority;
            --self.unread;
            message.readPending = YES;
            [message save];
            ++countMarkedRead;
        }
    }
    if (countMarkedRead > 0)
    {
        self.markReadRangePending = YES;
        [self save];
    }
    return countMarkedRead;
}

/* Call superclass to get description format
 */
-(NSString *)description
{
    return [super description];
}
@end
