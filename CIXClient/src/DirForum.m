//
//  DirForum.m
//  CIXClient
//
//  Created by Steve Palmer on 28/08/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "CIX.h"
#import "ForumMods.h"
#import "ForumSet.h"
#import "Parts.h"
#import "SendMail.h"
#import "StringExtensions.h"
#import "URLSessionExtensions.h"
#import "FMDatabase.h"

@implementation DirForum

/** Return whether this forum is closed.
 
 @return YES if the forum is closed, NO if it is open or private.
 */
-(BOOL)isClosed
{
    return ([self.type isEqual: @"c"]);
}

/** Return whether the authenticated user is a moderator of this forum. 
 
 If the moderator data for this forum is unavailable, the response is NO.
 
 @return YES if the authenticated user is a moderator of this forum, NO if
 the user is not or the information is not yet available.
 */
-(BOOL)isModerator
{
    return [self.moderators containsObject:CIX.username];
}

/** Return the date of the latest message in the forum.
 */
-(void)getDateOfLatestMessage
{
    NSThread * myThread = [[NSThread alloc] initWithTarget:self selector:@selector(loadDateOfLatestMessage:) object:nil];
    [myThread start];
}

-(void)loadDateOfLatestMessage:(id)sender
{
    NSDate * latestDate = nil;

    @synchronized(CIX.DBLock) {
        Folder * forum = [CIX.folderCollection folderByName:self.name];
        NSString * query = [NSString stringWithFormat:@"select max(M.date) from Message M where topicID in (select ID from Folder F where (F.parentID = %lli))", forum.ID];
        FMResultSet * results = [CIX.DB executeQuery:query];
        if (results != nil && [results next])
        {
            latestDate = [results dateForColumn:@"max(M.date)"];
        }
        [results close];
    }
    
    // Notify that the latest date was retrieved.
    dispatch_async(dispatch_get_main_queue(),^{
        NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:MAForumLatestDate object:latestDate];
    });
}

/** Request admission to a closed forum
 
 This method issues the appropriate API request to send a message to all the forum
 moderators to request admission to the forum.
 */
-(void)requestAdmission
{
    if (!CIX.online)
    {
        NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:MAForumRequestedAdmission object:[Response responseWithObject:self andError:CCResponse_Offline]];
        return;
    }

    NSError * error;
    
    NSBundle * frameworkBundle = [NSBundle bundleForClass:[DirForum class]];
    
    // Two separate templates - one plaintext and one HTML.
    NSString * HTMLtemplatePath = [frameworkBundle pathForResource:@"AdmissionRequestTemplate" ofType:@"html"];
    
    NSMutableString * HTMLtemplate = [NSMutableString stringWithContentsOfFile:HTMLtemplatePath encoding:NSUTF8StringEncoding error:&error];
    [HTMLtemplate replaceString:@"$username$" withString:CIX.username];
    [HTMLtemplate replaceString:@"$forum$" withString:self.name];

    NSString * textTemplatePath = [frameworkBundle pathForResource:@"AdmissionRequestTemplate" ofType:@"txt"];

    NSMutableString * textTemplate = [NSMutableString stringWithContentsOfFile:textTemplatePath encoding:NSUTF8StringEncoding error:&error];
    [textTemplate replaceString:@"$username$" withString:CIX.username];
    [textTemplate replaceString:@"$forum$" withString:self.name];
    
    J_SendMail * mailMessage = [[J_SendMail alloc] init];
    mailMessage.Text = textTemplate;
    mailMessage.HTML = HTMLtemplate;
    
    NSString * url = [NSString stringWithFormat:@"moderator/%@/sendmessage", self.name];
    NSURLRequest * request = [APIRequest post:url withData:mailMessage];
    if (request != nil)
    {
        LogFile * log = LogFile.logFile;
        [log writeLine:@"Requesting admission to forum %@", self.name];
        
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
                                                   resp.errorCode = CCResponse_JoinFailure_Limited;
                                               else
                                               {
                                                   NSString * responseString = [APIRequest responseTextFromData:data];
                                                   if (responseString != nil)
                                                   {
                                                       if (![responseString isEqualToString:@"Success"])
                                                           resp.errorCode = CCResponse_JoinFailure_NoSuchForum;
                                                       else
                                                           [log writeLine:@"Successfully sent admittance request for forum %@", self.name];
                                                   }
                                               }
                                           }
                                           
                                           // Alert interested parties about the result of the join
                                           dispatch_async(dispatch_get_main_queue(),^{
                                               NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
                                               [nc postNotificationName:MAForumRequestedAdmission object:resp];
                                           });
                                       }];
        [task resume];
    }
}

/** Return whether there are any pending actions on this forum.

 Pending actions are any actions initiated offline which require access to the server
 to complete.
 
 @return YES if this forum has pending actions. NO otherwise.
 */
-(BOOL)hasPending
{
    return self.detailsPending ||
           self.joinPending ||
           !IsEmpty(self.addedParts) ||
           !IsEmpty(self.removedParts) ||
           !IsEmpty(self.addedMods) ||
           !IsEmpty(self.removedMods);
}

/** Join this forum
 
 This method issues the appropriate API request to join the authenticated user to
 this forum on the server. The Join request occurs asynchronously and a MAForumJoined
 notification is posted on completion of the join.
 */
-(void)join
{
    if (!CIX.online)
    {
        NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:MAForumJoined object:[Response responseWithObject:self andError:CCResponse_Offline]];
        
        self.joinPending = YES;
        [self save];
        return;
    }

    NSString * encodedForumName = [self.name stringByReplacingOccurrencesOfString:@"." withString:@"~"];
    NSString * url = [NSString stringWithFormat:@"forums/%@/join", encodedForumName];
    NSURLRequest * request = [APIRequest get:url withQuery:@"mark=true"];
    if (request != nil)
    {
        LogFile * log = LogFile.logFile;
        [log writeLine:@"Joining forum %@", self.name];
        
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
                                               if (data == nil)
                                                   resp.errorCode = CCResponse_JoinFailure_Limited;
                                               else
                                               {
                                                   NSString * responseString = [APIRequest responseTextFromData:data];
                                                   if (responseString != nil)
                                                   {
                                                       if (![responseString isEqualToString:@"Success"])
                                                           resp.errorCode = CCResponse_JoinFailure_NoSuchForum;
                                                       else
                                                       {
                                                           [log writeLine:@"Successfully joined forum %@", self.name];
                                                           
                                                           // Create the top-level forum folder now and kick off a sync
                                                           // to get the rest of the data.
                                                           Folder * forum = [CIX.folderCollection folderByName:self.name];
                                                           if (forum == nil)
                                                           {
                                                               forum = [Folder new];
                                                               forum.name = self.name;
                                                               forum.displayName = self.name;
                                                               forum.flags = FolderFlagsRecent;
                                                               forum.parentID = -1;
                                                               
                                                               [CIX.folderCollection add:forum];
                                                           }
                                                           resp.object = forum;
                                                           
                                                           // Need to remove any existing resign flag for the case
                                                           // where the forum was resigned earlier but kept in the database.
                                                           forum.flags &= ~FolderFlagsResigned;
                                                           [forum save];
                                                           
                                                           [CIX.folderCollection refresh:NO];
                                                       }
                                                   }
                                               }
                                               
                                               self.joinPending = NO;
                                               [self save];
                                           }
                                           
                                           // Alert interested parties about the result of the join
                                           dispatch_async(dispatch_get_main_queue(),^{
                                               NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
                                               [nc postNotificationName:MAForumJoined object:resp];
                                           });
                                       }];
        [task resume];
    }
}

/** Return an array of all moderators of the forum.
 
 This method returns a string array of all moderators of this forum, where each
 moderator is identified by their CIX username. The caller should subscribe to the
 MAModeratorsUpdated event to be notified when the list of moderators change since
 if the current list has not been retrieved from the API then an asynchronous call
 is made to the API server to return the list and the method returns immediately
 with an empty array.
 
 The array cannot be modified. To add or remove moderators, add names to the
 mutable addedModerators and removedModerators array instead.
 
 @return An NSArray of NSString objects for each moderator.
 */
-(NSArray *)moderators
{
    if (IsEmpty(self.mods) && CIX.online && !_isModeratorsRefreshing)
    {
        self.mods = @"";
        _isModeratorsRefreshing = YES;

        NSString * encodedForumName = [self.name stringByReplacingOccurrencesOfString:@"." withString:@"~"];
        NSString * url = [NSString stringWithFormat:@"forums/%@/moderators", encodedForumName];
        NSURLRequest * request = [APIRequest get:url];
        if (request != nil)
        {
            [LogFile.logFile writeLine:@"Updating list of moderators for %@", self.name];
            
            NSURLSession * session = [NSURLSession sharedSession];
            NSURLSessionDataTask * task = [session dataTaskWithRequest:request
                                                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                           {
                                               if (error != nil)
                                                   [CIX reportServerErrors:__PRETTY_FUNCTION__ error:error];
                                               else
                                               {
                                                   JSONModelError * jsonError = nil;
                                                   
                                                   J_ForumMods * mods = [[J_ForumMods alloc] initWithData:data error:&jsonError];
                                                   if (jsonError == nil)
                                                   {
                                                       NSMutableArray * tempArray = [NSMutableArray array];
                                                       for (J_Mod * mod in mods.Mods)
                                                           [tempArray addObject:mod.Name];
                                                       
                                                       // Commit to the database
                                                       self.mods = [tempArray componentsJoinedByString:@","];
                                                       [self save];
                                                       
                                                       [LogFile.logFile writeLine:@"List of moderators for %@ updated", self.name];
                                                       
                                                       // Notify interested parties that the moderator list has changed
                                                       dispatch_async(dispatch_get_main_queue(),^{
                                                           NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
                                                           [nc postNotificationName:MAModeratorsUpdated object:self];
                                                       });
                                                   }
                                               }
                                               _isModeratorsRefreshing = NO;
                                           }];
            [task resume];
        }
    }
    return IsEmpty(self.mods) ? @[] : [self.mods componentsSeparatedByString:@","];
}

/** Add the array of users as moderators of this forum.
 
 @param names An NSArray of strings of the users to be added as moderators
 */
-(void)addModerators:(NSArray *)names
{
    self.addedMods = [names componentsJoinedByString:@","];
}

/** Remove the array of users as moderators of this forum.
 
 @param names An NSArray of strings of the users to be removed as moderators
 */
-(void)removeModerators:(NSArray *)names
{
    self.removedMods = [names componentsJoinedByString:@","];
}

/** Return an array of moderators that have been added
 
 The array is a list of moderators whose addition is pending the next connection. This
 may be empty.
 
 @return An array of strings representing moderators that have been added.
 */
-(NSArray *)addedModerators
{
    return IsEmpty(self.addedMods) ? @[] : [self.addedMods componentsSeparatedByString:@","];
}

/** Return an array of moderators that have been removed
 
 The array is a list of moderators whose removal is pending the next connection. This
 may be empty.
 
 @return An array of strings representing moderators that have been removed.
 */
-(NSArray *)removedModerators
{
    return IsEmpty(self.removedMods) ? @[] : [self.removedMods componentsSeparatedByString:@","];
}

/** Return an array of all participants of the forum
 
 This method returns a string array of all participants of this forum, where each
 participant is identified by their CIX username. The caller should subscribe to the
 MAParticipantsUpdated event to be notified when the list of participants change since
 if the current list has not been retrieved from the API then an asynchronous call
 is made to the API server to return the list and the method returns immediately
 with an empty array.
 
 The array cannot be modified. To add or remove moderators, add names to the
 mutable addedParticipants and removedParticipants array instead.
 
 @return An NSArray of NSString objects for each participant.
 */
-(NSArray *)participants
{
    if (IsEmpty(self.parts) && CIX.online && !_isParticipantsRefreshing)
    {
        self.parts = @"";
        _isParticipantsRefreshing = YES;

        NSString * encodedForumName = [self.name stringByReplacingOccurrencesOfString:@"." withString:@"~"];
        NSString * url = [NSString stringWithFormat:@"forums/%@/participants", encodedForumName];
        NSURLRequest * request = [APIRequest get:url withQuery:@"maxresults=10000"];
        if (request != nil)
        {
            [LogFile.logFile writeLine:@"Updating list of participants for %@", self.name];
            
            NSURLSession * session = [NSURLSession sharedSession];
            NSURLSessionDataTask * task = [session dataTaskWithRequest:request
                                                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                           {
                                               if (error != nil)
                                                   [CIX reportServerErrors:__PRETTY_FUNCTION__ error:error];
                                               else
                                               {
                                                   JSONModelError * jsonError = nil;
                                                   
                                                   J_Parts * parts = [[J_Parts alloc] initWithData:data error:&jsonError];
                                                   if (jsonError == nil)
                                                   {
                                                       NSMutableArray * tempArray = [NSMutableArray array];
                                                       for (J_Part * part in parts.Users)
                                                           [tempArray addObject:part.Name];
                                                       
                                                       // Commit to the database
                                                       self.parts = [tempArray componentsJoinedByString:@","];
                                                       [self save];
                                                       
                                                       [LogFile.logFile writeLine:@"List of participants for %@ updated", self.name];
                                                       
                                                       // Notify interested parties that the participants list has changed
                                                       dispatch_async(dispatch_get_main_queue(),^{
                                                           NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
                                                           [nc postNotificationName:MAParticipantsUpdated object:self];
                                                       });
                                                   }
                                               }
                                               _isParticipantsRefreshing = NO;
                                           }];
            [task resume];
        }
    }
    return IsEmpty(self.parts) ? @[] : [self.parts componentsSeparatedByString:@","];
}

/** Add the array of users as participants of this forum.
 
 @param names An NSArray of strings of the users to be added as participants
 */
-(void)addParticipants:(NSArray *)names
{
    self.addedParts = [names componentsJoinedByString:@","];
}

/** Remove the array of users as participants of this forum.
 
 @param names An NSArray of strings of the users to be removed as participants
 */
-(void)removeParticipants:(NSArray *)names
{
    self.removedParts = [names componentsJoinedByString:@","];
}

/** Return an array of participants that have been added
 
 The array is a list of participants whose addition is pending the next connection. This
 may be empty.
 
 @return An array of strings representing participants that have been added.
 */
-(NSArray *)addedParticipants
{
    return IsEmpty(self.addedParts) ? @[] : [self.addedParts componentsSeparatedByString:@","];
}

/** Return an array of participants that have been removed
 
 The array is a list of participants whose removal is pending the next connection. This
 may be empty.
 
 @return An array of strings representing participants that have been removed.
 */
-(NSArray *)removedParticipants
{
    return IsEmpty(self.removedParts) ? @[] : [self.removedParts componentsSeparatedByString:@","];
}

/** Refresh the list of participants and moderators
 */
-(void)refresh
{
    self.parts = @"";
    self.mods = @"";
    
    [self participants];
    [self moderators];
}

/** Update this forum in the database.

 This method should be called if any of the properties of the forum
 have been modified and the changes should be committed. To avoid excessive
 updates, the responsibility for committing the changes is left to the caller.
 */
-(void)update
{
    [self save];
    
    // Alert interested parties about this change to the forum
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:MAForumChanged object:[[Response alloc] initWithObject:self andError:CCResponse_NoError]];
    
    // Update on the server
    [self syncDetails];
    [self syncParticipantsAndModerators];
}

/* Sync this DirForum object with the server based on what is
 * pending synchronisation.
 */
-(void)sync
{
    if (self.detailsPending)
        [self syncDetails];
    
    if (self.joinPending)
        [self join];
    
    [self syncParticipantsAndModerators];
}

/* Synchronise any changes to the list of participants and moderators by
 * spawning a separate thread to handle these.
 */
-(void)syncParticipantsAndModerators
{
    if (!IsEmpty(self.addedParts) || !IsEmpty(self.removedParts))
    {
        NSThread * myThread = [[NSThread alloc] initWithTarget:self selector:@selector(syncParticipants:) object:nil];
        [myThread start];
    }
    
    if (!IsEmpty(self.addedMods) || !IsEmpty(self.removedMods))
    {
        NSThread * myThread = [[NSThread alloc] initWithTarget:self selector:@selector(syncModerators:) object:nil];
        [myThread start];
    }
}

/* Update the forum details on the server.
 */
-(void)syncDetails
{
    if (!CIX.online)
    {
        self.detailsPending = YES;
        return;
    }
    
    LogFile * log = LogFile.logFile;
    [log writeLine:@"Updating forum %@ to server", self.name];
    
    J_Forums * newForum = [[J_Forums alloc] init];
    newForum.Name = self.name;
    newForum.Type = self.type;
    newForum.Title = self.title;
    newForum.Description = self.desc;
    newForum.Category = self.cat;
    newForum.SubCategory = self.sub;
    
    NSURLRequest * request = [APIRequest post:@"moderator/forumupdate" withData:newForum];
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
                                                   if ([responseString isEqualToString:@"Success"])
                                                   {
                                                       [log writeLine:@"Forum %@ successfully updated", self.name];
                                                       self.detailsPending = NO;
                                                       [self save];
                                                   }
                                               }
                                           }
                                       }];
        [task resume];
    }
}

/* Add and remove participants from the forum
 */
-(void)syncParticipants:(id)sender
{
    if (CIX.online)
    {
        for (NSString * part in self.addedParticipants)
        {
            NSString * encodedForumName = [self.name stringByReplacingOccurrencesOfString:@"." withString:@"~"];
            NSString * url = [NSString stringWithFormat:@"moderator/%@/%@/partadd", encodedForumName, part];
            NSURLRequest * request = [APIRequest get:url];
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
                       if ([responseString isEqualToString:@"Success"])
                       {
                           LogFile * log = LogFile.logFile;
                           [log writeLine:@"User %@ successfully added to %@", part, self.name];
                       }
                   }
                }
            }
        }

        for (NSString * part in self.removedParticipants)
        {
            NSString * encodedForumName = [self.name stringByReplacingOccurrencesOfString:@"." withString:@"~"];
            NSString * url = [NSString stringWithFormat:@"moderator/%@/%@/partrem", encodedForumName, part];
            NSURLRequest * request = [APIRequest get:url];
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
                       if ([responseString isEqualToString:@"Success"])
                       {
                           LogFile * log = LogFile.logFile;
                           [log writeLine:@"User %@ successfully removed from %@", part, self.name];
                       }
                   }
                }
            }
        }

        // Clear out the current participant lists to force a refresh from the server
        self.addedParts = @"";
        self.removedParts = @"";
        self.parts = @"";
        [self save];
        
        // Notify interested parties that the participant list has changed
        dispatch_async(dispatch_get_main_queue(),^{
            NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
            [nc postNotificationName:MAParticipantsUpdated object:self];
        });
    }
}

/* Add and remove moderators from the forum
 */
-(void)syncModerators:(id)sender
{
    if (CIX.online)
    {
        for (NSString * user in self.addedModerators)
        {
            NSString * encodedForumName = [self.name stringByReplacingOccurrencesOfString:@"." withString:@"~"];
            NSString * url = [NSString stringWithFormat:@"moderator/%@/%@/modadd", encodedForumName, user];
            NSURLRequest * request = [APIRequest get:url];
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
                        if ([responseString isEqualToString:@"Success"])
                        {
                            LogFile * log = LogFile.logFile;
                            [log writeLine:@"Moderator %@ successfully added to %@", user, self.name];
                        }
                    }
                }
            }
        }
        
        for (NSString * user in self.removedModerators)
        {
            NSString * encodedForumName = [self.name stringByReplacingOccurrencesOfString:@"." withString:@"~"];
            NSString * url = [NSString stringWithFormat:@"moderator/%@/%@/modrem", encodedForumName, user];
            NSURLRequest * request = [APIRequest get:url];
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
                        if ([responseString isEqualToString:@"Success"])
                        {
                            LogFile * log = LogFile.logFile;
                            [log writeLine:@"Moderator %@ successfully removed from %@", user, self.name];
                        }
                    }
                }
            }
        }
        
        // Clear out the current moderator lists to force a refresh from the server
        self.addedMods = @"";
        self.removedMods = @"";
        self.mods = @"";
        [self save];
        
        // Notify interested parties that the moderator list has changed
        dispatch_async(dispatch_get_main_queue(),^{
            NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
            [nc postNotificationName:MAModeratorsUpdated object:self];
        });
    }
}

/* Call superclass to get description format
 */
-(NSString *)description
{
    return [super description];
}
@end
