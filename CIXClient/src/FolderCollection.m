//
//  FolderCollection.m
//  CIXClient
//
//  Created by Steve Palmer on 21/08/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "CIX.h"
#import "FMDatabase.h"
#import "Folder_Private.h"
#import "Message_Private.h"
#import "UserForumTopicResultSet.h"
#import "InterestingThreads.h"
#import "MessageResultSet.h"
#import "DateExtensions.h"
#import "StarSet.h"
#import "CIXThread.h"

@implementation FolderCollection

/* Initialise ourself.
 */
-(id)init
{
    if ((self = [super init]) != nil)
        _foldersByName = [[NSMutableDictionary alloc] init];

    return self;
}

/* Synchronise all forums.
 */
-(void)sync
{
    if (CIX.online)
    {
        @try {
            for (Folder * folder in self.folders.allValues)
            {
                if ([folder hasPending])
                    [folder sync];
            }
            [self postMessages];
            [self starMessages];
            [self withdrawMessages];
            [self refresh:YES];
        }
        @catch (NSException *exception) {
            [CIX reportServerExceptions:__PRETTY_FUNCTION__ exception:exception];
        }
    }
}

/* Do the shutdown sync.
 * Note: all sync actions here MUST be synchronous and wait until completion before
 * returning.
 */
-(void)closeSync
{
    if (CIX.online)
    {
        @try {
            for (Folder * folder in self.folders.allValues)
            {
                if ([folder hasPending])
                    [folder closeSync];
            }
        }
        @catch (NSException *exception) {
            [CIX reportServerExceptions:__PRETTY_FUNCTION__ exception:exception];
        }
    }
}

/** Return a dictionary of all folders.
 
 The returned dictionary contains one value for each folder where the key
 is the folder ID and the value is the associated Folder object.
 
 @return An NSDictionary object representing all folders.
 */
-(NSDictionary *)folders
{
    if (_folders == nil)
    {
        NSArray * results = [Folder allRows];
        
        _folders = [[NSMutableDictionary alloc] init];

        // We also create a dummy 'root' folder with an ID of -1 which has all
        // top level folders as root. This simplifies the management of the folder
        // tree.
        _root = [Folder new];
        _root.ID = -1;
        
        _folders[[NSNumber numberWithLongLong:-1]] = _root;
        
        for (Folder * folder in results)
        {
            Folder * parentFolder = [folder parentFolder];
            [parentFolder add:folder];
            [self initWithFolder:folder];
        }
    }
    return _folders;
}

/** Return an NSArray of all folders.
 
 @return An NSArray of all folders
 */
-(NSArray *)allFolders
{
    return _folders.allValues;
}

/** Return an NSArray of messages satisfying a criteria
 
 @param criteria A SQL format string specifying the criteria
 @return An NSArray of all messages that satisify the specified criteria
 */
-(NSArray *)messagesWithCriteria:(NSString *)criteria
{
    return [self syncWithCache:[Message allRowsWithQuery:[NSString stringWithFormat:@" where %@", criteria]]];
}

/* Add one folder to the folder collection as loaded from
 * the database, and thus the folder ID as set is used.
 */
-(void)initWithFolder:(Folder *)newFolder
{
    NSNumber * key = [NSNumber numberWithLongLong:newFolder.ID];

    if ([_folders objectForKey:key] == nil)
        _folders[key] = newFolder;

    if (newFolder.parentID == -1)
        _foldersByName[newFolder.name] = newFolder;
}

/** Add this folder to the FolderCollection
 
 The folder is added as a child folder to its given parent and then
 committed to the database.
 
 @param folder The Folder to insert into the collection.
 */
-(void)add:(Folder *)folder
{
    Folder * parentFolder = [folder parentFolder];
    [parentFolder add:folder];
    [folder save];
    [self initWithFolder:folder];
}

/** Remove the specified folder from the collection.
 
 The folder is removed from its parent's collection and then also
 removed from the database.
 
 @param folder The Folder to remove from the collection
 */
-(void)remove:(Folder *)folder
{
    Folder * parentFolder = [folder parentFolder];
    [parentFolder remove:folder];

    NSNumber * key = [NSNumber numberWithLongLong:folder.ID];
    [_folders removeObjectForKey:key];
}

/** Return whether the user is a member of a forum
 
 @param forumName The name of the forum to check
 @return YES if the user is a member of the specified forum, NO otherwise.
 */
-(BOOL)isJoined:(NSString *)forumName
{
    return [_foldersByName objectForKey:forumName] != nil;
}

/** Return the total count of unread messages
 
 @return The total number of unread messages
 */
-(NSInteger)totalUnread
{
    NSInteger count = 0;
    for (Folder * folder in _folders.allValues)
        count += folder.unread;
    return count;
}

/** Return the total count of unread priority messages
 
 @return The total number of unread priority messages
 */
-(NSInteger)totalUnreadPriority
{
    NSInteger count = 0;
    for (Folder * folder in _folders.allValues)
        count += folder.unreadPriority;
    return count;
}

/* Given an NSArray of Message objects retrieved from the database, this function
 * syncs each Message element with the cached version held by the folder.
 */
-(NSArray *)syncWithCache:(NSArray *)messages
{
    NSMutableArray * realArray = [NSMutableArray array];
    for (Message * message in messages)
    {
        Folder * folder = [CIX.folderCollection folderByID:message.topicID];
        [realArray addObject:[folder getCachedMessage:message]];
    }
    return realArray;
}

/* Return a folder from the collection given its ID
 */
-(Folder *)folderByID:(ID_type)ID
{
    NSNumber * key = [NSNumber numberWithLongLong:ID];
    return [self.folders objectForKey:key];
}

/* Return a top-level forum from the collection given its Name
 */
-(Folder *)folderByName:(NSString *)forumName
{
    return [_root childByName:forumName];
}

/* Support fast enumeration on the folders list.
 */
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])stackbuf count:(NSUInteger)len
{
    if (state->state == 0)
        _allFolders = [self.folders allValues];

    return [_allFolders countByEnumeratingWithState:state objects:stackbuf count:len];
}

/* Post all pending messages to the server
 */
-(void)postMessages
{
    NSArray * pending = [self syncWithCache:[Message allRowsWithQuery:[NSString stringWithFormat:@" where postPending=1"]]];
    for (Message * message in pending)
        [message sync];
}

/* Post all pending messages to the server
 */
-(void)starMessages
{
    NSArray * pending = [self syncWithCache:[Message allRowsWithQuery:[NSString stringWithFormat:@" where starPending=1"]]];
    for (Message * message in pending)
        [message sync];
}

/* Withdraw any pending messages
 */
-(void)withdrawMessages
{
    NSArray * pending = [self syncWithCache:[Message allRowsWithQuery:[NSString stringWithFormat:@" where withdrawPending=1"]]];
    for (Message * message in pending)
        [message sync];
}

/** Retrieve the list of interesting threads
 
 Fires a MAInterestingThreadsRefreshed notification when the list has been retrieved.
 */
-(void)refreshInterestingThreads
{
    NSURLRequest * request = [APIRequest get:@"forums/interestingthreads"];
    if (request != nil)
    {
        [LogFile.logFile writeLine:@"Refreshing latest list of interesting threads"];
        
        NSURLSession * session = [NSURLSession sharedSession];
        NSURLSessionDataTask * task = [session dataTaskWithRequest:request
                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                       {
                                           if (error == nil)
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
                                                   
                                                   J_InterestingThreadSet * msgs = [[J_InterestingThreadSet alloc] initWithData:data error:&jsonError];
                                                   if (jsonError != nil)
                                                       resp.errorCode = CCResponse_NoSuchForum;
                                                   else
                                                   {
                                                       NSMutableArray * arrayOfThreads = [NSMutableArray array];
                                                       for (J_InterestingThread * thread in msgs.Messages)
                                                       {
                                                           CIXThread * cixThread = [[CIXThread alloc] init];
                                                           cixThread.author = thread.Author;
                                                           cixThread.body = thread.Body;
                                                           cixThread.forum = thread.Forum;
                                                           cixThread.topic = thread.Topic;
                                                           cixThread.remoteID = thread.RootID;
                                                           cixThread.date = [CIX.CIXDateFormatter dateFromString:thread.DateTime];
                                                           [arrayOfThreads addObject:cixThread];
                                                       }
                                                       resp.object = arrayOfThreads;
                                                   }
                                               }
                                               
                                               // Notify interested parties that the list of interesting
                                               // threads has changed.
                                               dispatch_async(dispatch_get_main_queue(),^{
                                                   NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
                                                   [nc postNotificationName:MAInterestingThreadsRefreshed object:resp];
                                               });
                                           }
                                       }];
        [task resume];
    }
}

/** Sync with the API server using the Fast Sync mechanism.

 @return YES if the sync was able to complete, NO if we need to fall back on slow sync.
 */
-(BOOL)refreshWithFastSync
{
    // Retrieve last sync date and time. If this is the first ever sync
    // then default to the last 2 days worth.
    NSDate * sinceDate = CIX.lastSyncDate;
    if (sinceDate == nil || [sinceDate isEqualToDate:[NSDate dateWithTimeIntervalSince1970:0]])
        return NO;
    
    // If it has been more than 5 days since the last fast sync, do a full sync instead.
    if ([sinceDate compare:[NSDate.date dateByAddingTimeInterval:-(60*60*24*5)]] == NSOrderedAscending)
        return NO;
    
    NSURLRequest * request = [APIRequest get:@"user/sync" withQuery:[NSString stringWithFormat:@"since=%@&maxresults=5000", [CIX.dateFormatter stringFromDate:sinceDate]]];
    if (request != nil)
    {
        _isInRefresh = YES;

        LogFile * log = LogFile.logFile;
        [log writeLine:@"Sync all forums started"];
        
        // Mark the last sync date
        __block NSDate * latestDate = [sinceDate toLocalDate];
        
        NSURLSession * session = [NSURLSession sharedSession];
        NSURLSessionDataTask * task = [session dataTaskWithRequest:request
                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                       {
                                           Response * resp = [[Response alloc] initWithObject:nil];
                                           if (error != nil)
                                           {
                                               [CIX reportServerErrors:__PRETTY_FUNCTION__ error:error];
                                               resp.errorCode = CCResponse_ServerError;
                                           }
                                           else
                                           {
                                               JSONModelError * jsonError = nil;
                                               NSMutableArray * changedFolders = [NSMutableArray array];
                                               NSMutableArray * topicsToRefresh = [NSMutableArray array];
                                               int countOfNewMessages = 0;
                                               BOOL needFullSync = NO;
                                               
                                               J_MessageResultSet2 * msgs = [[J_MessageResultSet2 alloc] initWithData:data error:&jsonError];
                                               if (jsonError != nil)
                                                   resp.errorCode = CCResponse_NoSuchForum;
                                               else
                                               {
                                                   @synchronized(CIX.DBLock) {
                                                       [CIX.DB beginTransaction];
                                                       
                                                       Folder * previousTopic = nil;
                                                       for (J_Message2 * msg in msgs.Messages)
                                                       {
                                                           // We can only refresh folders that actually exist. If this is a message
                                                           // in a newly subscribed folder then we need to force a full refresh
                                                           // instead. Clear the last sync to force a full refresh next time.
                                                           Folder * forum = [self folderByName:msg.Forum];
                                                           Folder * topic = nil;
                                                           if (forum != nil)
                                                               topic = [forum childByName:msg.Topic];
                                                           
                                                           if (topic == nil)
                                                           {
                                                               needFullSync = YES;
                                                               continue;
                                                           }
                                                           if (topic.messages.count == 0)
                                                           {
                                                               // Empty folders require a full refresh on the first time.
                                                               if (![topicsToRefresh containsObject:topic])
                                                                   [topicsToRefresh addObject:topic];
                                                               continue;
                                                           }
                                                           
                                                           Message * message = [topic.messages messageByID:msg.ID];
                                                           if (message == nil)
                                                           {
                                                               message = [Message new];
                                                               message.remoteID = msg.ID;
                                                               message.author = msg.Author;
                                                               message.body = msg.Body;
                                                               message.date = [CIX.CIXDateFormatter dateFromString:msg.DateTime];
                                                               message.commentID = msg.ReplyTo;
                                                               message.rootID = msg.RootID;
                                                               message.topicID = topic.ID;
                                                               message.starred = msg.Starred;
                                                               message.priority = msg.Priority;
                                                               message.unread = msg.Unread;
                                                               
                                                               [CIX.ruleCollection applyRules:message];
                                                               
                                                               [topic.messages addInternal:message];
                                                               
                                                               if (message.unread)
                                                               {
                                                                   ++topic.unread;
                                                                   if (message.priority)
                                                                       ++topic.unreadPriority;
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
                                                                   topic.unread += message.unread ? 1 : -1;
                                                                   if (message.priority)
                                                                       topic.unreadPriority += message.unread ? 1 : -1;
                                                               }
                                                               
                                                               message.body = msg.Body;
                                                               [message save];
                                                           }

                                                           NSDate * lastUpdate = [CIX.CIXDateFormatter dateFromString:msg.LastUpdate];
                                                           if (lastUpdate > latestDate)
                                                               latestDate = lastUpdate;

                                                           // Save the topic when we switch to a new one
                                                           if (previousTopic != nil && previousTopic != topic)
                                                           {
                                                               [changedFolders addObject:previousTopic];
                                                               [previousTopic save];
                                                           }
                                                           previousTopic = topic;
                                                       }
                                                       
                                                       if (previousTopic != nil)
                                                       {
                                                           [previousTopic save];
                                                           [changedFolders addObject:previousTopic];
                                                       }

                                                       [CIX.DB commit];
                                                   }
                                                   
                                                   [LogFile.logFile writeLine:@"Sync completed with %d new messages", countOfNewMessages];
                                                   
                                                   // Set the next sync date to the latest update plus 1 second
                                                   [CIX setLastSyncDate:needFullSync ?
                                                        [NSDate defaultDate] :
                                                        [[latestDate fromLocalDate] dateByAddingTimeInterval:-1]];
                                                   
                                                   // Refresh each topic that requires refreshing
                                                   for (Folder * topic in topicsToRefresh)
                                                       [topic refresh];

                                                   // Notify interested parties that each folder has changed
                                                   for (Folder * folder in changedFolders)
                                                   {
                                                       dispatch_async(dispatch_get_main_queue(),^{
                                                           NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
                                                           resp.object = folder;
                                                           [nc postNotificationName:MAFolderRefreshed object:resp];
                                                       });
                                                   }
                                               }
                                           }
                                       }];
        [task resume];
    }
    return YES;
}

/** Refresh the folders collection
 
 Refresh the forums list and pull down the metadata that specifies which forums
 have changed on the server.
 */
-(void)refresh:(BOOL)useFastSync
{
    if (!CIX.online || _isInRefresh)
        return;
    
    if (useFastSync && [self refreshWithFastSync])
    {
        _isInRefresh = NO;
        return;
    }
    
    NSURLRequest * request = [APIRequest get:@"user/alltopics" withQuery:@"maxresults=5000"];
    if (request != nil)
    {
        _isInRefresh = YES;
        
        LogFile * log = LogFile.logFile;
        [log writeLine:@"Start refreshing all forums"];
        
        // Mark the date of this refresh so that fast sync has something to
        // work from.
        [CIX setLastSyncDate:NSDate.date];
        
        NSURLSession * session = [NSURLSession sharedSession];
        NSURLSessionDataTask * task = [session dataTaskWithRequest:request
                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                       {
                                           if (error != nil)
                                               [CIX reportServerErrors:__PRETTY_FUNCTION__ error:error];
                                           else
                                           {
                                               JSONModelError * jsonError = nil;
                                               
                                               J_UserForumTopicResultSet2 * topics = [[J_UserForumTopicResultSet2 alloc] initWithData:data error:&jsonError];
                                               if (jsonError == nil)
                                               {
                                                   NSMutableArray * topicsToRefresh = [NSMutableArray array];
                                                   NSMutableArray * allForums = [NSMutableArray array];
                                                   int newTopics = 0;
                                                   
                                                   @synchronized(CIX.DBLock) {
                                                       [CIX.DB beginTransaction];
                                                       for (J_UserForumTopic2 * item in topics.UserTopics)
                                                       {
                                                           Folder * forum = [self folderByName:item.Forum];
                                                           FolderFlags flags = FolderFlagsRecent;
                                                           
                                                           [allForums addObject:item.Forum];
                                                           
                                                           // First handle the forum for the topic
                                                           if (item.Flags & UserForumTopicFlagsCannotResign)
                                                               flags |= FolderFlagsCannotResign;
                                                           
                                                           if (forum == nil)
                                                           {
                                                               forum = [Folder new];
                                                               forum.name = item.Forum;
                                                               forum.displayName = item.Forum;
                                                               forum.flags = flags;
                                                               forum.parentID = -1;
                                                               
                                                               [self add:forum];
                                                           }
                                                           else if (forum.resignPending)
                                                           {
                                                               // Possible race condition
                                                               continue;
                                                           }
                                                           if (forum.isResigned)
                                                           {
                                                               forum.flags &= ~FolderFlagsResigned;
                                                               [log writeLine:@"Forum %@ resigned locally but was rejoined on server", forum.name];
                                                               [forum save];
                                                           }
                                                           if (forum.flags != flags || ![forum.displayName isEqualToString:item.Forum])
                                                           {
                                                               forum.flags = flags;
                                                               forum.displayName = item.Forum;
                                                               [forum save];
                                                           }
                                                           
                                                           // Then handle the topic itself.
                                                           Folder * topic = [forum childByName:item.Topic];
                                                           flags = 0;
                                                           
                                                           if (item.Flags & UserForumTopicFlagsReadOnly)
                                                               flags |= FolderFlagsReadOnly;
                                                           
                                                           if (item.Latest || item.UnRead > 0 || topic.isRecent)
                                                               flags |= FolderFlagsRecent;
                                                           
                                                           if (item.Flags & UserForumTopicFlagsNoticeboard)
                                                               flags |= FolderFlagsOwnerCommentsOnly;
                                                           
                                                           if (topic == nil)
                                                           {
                                                               topic = [Folder new];
                                                               topic.name = item.Topic;
                                                               topic.displayName = item.Name;
                                                               topic.parentID = forum.ID;
                                                               topic.flags = flags;
                                                               
                                                               [self add:topic];
                                                               ++newTopics;
                                                           }
                                                           else
                                                           {
                                                               if (topic.flags != flags || ![topic.displayName isEqualToString:item.Name])
                                                               {
                                                                   topic.displayName = item.Name;
                                                                   topic.flags = flags;
                                                                   [topic save];
                                                               }
                                                           }

                                                           if (topic.unread != item.UnRead)
                                                               [topicsToRefresh addObject:topic];
                                                       }
                                                       [CIX.DB commit];
                                                   }
                                                   
                                                   if (newTopics > 0)
                                                       [log writeLine:@"%d new topics found", newTopics];
                                                   
                                                   // Mark as resigned any local forum not in the allForums list
                                                   for (Folder * forum in self.allFolders)
                                                   {
                                                       if (IsTopLevelFolder(forum) && ![allForums containsObject:forum.name] && !forum.isResigned)
                                                       {
                                                           forum.flags = FolderFlagsResigned;
                                                           [forum save];
                                                       }
                                                   }
                                                   
                                                   // Refresh each topic that requires refreshing
                                                   for (Folder * topic in topicsToRefresh)
                                                       [topic refresh];
                                                   
                                                   // Notify about the change
                                                   if (newTopics > 0)
                                                       dispatch_async(dispatch_get_main_queue(),^{
                                                           NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
                                                           [nc postNotificationName:MAFolderAdded object:nil];
                                                       });
                                                   
                                                   // Notify if any changes occurred.
                                                   dispatch_async(dispatch_get_main_queue(),^{
                                                       NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
                                                       [nc postNotificationName:MAFolderUpdated object:nil];
                                                   });
                                               }
                                           }
                                           [log writeLine:@"Finished refreshing all forums"];

                                           _isInRefresh = NO;
                                       }];
        [task resume];
    }
}
@end
