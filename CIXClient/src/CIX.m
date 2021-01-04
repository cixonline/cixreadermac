//
//  CIX.m
//  CIXClient
//
//  Created by Steve Palmer on 31/07/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "CIX.h"
#import "FMDatabase.h"
#import "StringExtensions.h"
#import "FileManagerExtensions.h"
#import "Who.h"
#import "Account.h"
#import "Global.h"

// The CIX object is a class object. We should maybe think about changing
// it to a singleton.
static FMDatabase * _db = nil;
static NSString * _homeFolder = nil;
static NSDateFormatter * _sqlDateFormat = nil;
static NSDateFormatter * _cixDateFormat = nil;
static NSTimer * _uiTimer = nil;
static BOOL _onlineState = YES;
static int _taskInterval = 60.0;
static Global * _global;

static FolderCollection * _folderCollection = nil;
static DirectoryCollection * _directoryCollection = nil;
static ProfileCollection * _profileCollection = nil;
static ConversationCollection * _conversationCollection = nil;
static RuleCollection * _ruleCollection = nil;

static NSString * _username;
static int _userAccountType;

static const int FirstRunInterval = 2.0;

@implementation CIX

/** Return the database instance.
 
 This property returns an object that can be used to access the database cache.
 The init method must first be called to ensure that the database is correctly
 initialised first.
 
 @return An FMDatabase database access object.
 */
+(FMDatabase *)DB
{
    return _db;
}

/** Change the home folder for CIXReader data files.
 
 This method is optional and if not called, the default home folder will be used
 and can be obtained from the homeFolder property. If you are changing this to
 an alternative location, be sure that it is within the sandbox container or
 the init method will fail!
 
 Changing the home folder should be done before the init method is called.
 
 @param newHomeFolder A fully qualified path to the CIXReader home folder.
 */
+(void)setHomeFolder:(NSString *)newHomeFolder
{
    _homeFolder = newHomeFolder;
}

/** Return the home folder for CIXReader data files
 
 This is, by default, located in the Application Support folder on the users system
 but can be altered as required. Note that on Sandboxes applications, this cannot be
 relocated outside of the sandbox container.
 
 @return The fully qualified path of the CIXReader data folder.
 */
+(NSString *)homeFolder
{
    if (_homeFolder == nil)
        _homeFolder = [[NSFileManager defaultManager] applicationSupportDirectory];

    return _homeFolder;
}

/** Set the current CIX username.
 
 This method sets the username part of the credentials for subsequent access to the API
 server. No attempt it made to validate the username as part of this method. An invalid
 username will result in authentication failures from the CIX service on the next access
 to the API server.
 
 It is recommended that the username be set before the init method is called.
 
 @param newUsername The new CIX username to be used
 */
+(void)setUsername:(NSString *)newUsername
{
    _username = newUsername;
}

/** Return the current CIX username.
 
 If no username has been specified, the return value is an empty string
 and guaranteed never to be nil.
 
 @return The current authenticated username.
 */
+(NSString *)username
{
    return SafeString(_username);
}

/** Return the date and time of the last sync
 
 @return The date and time of the last sync in an NSDate object.
 */
+(NSDate *)lastSyncDate
{
    return _global.databaseLastSyncDate;
}

/** Set the date and time of the last sync
 
 @param date The date and time of the last sync
 */
+(void)setLastSyncDate:(NSDate *)date
{
    [_global setDatabaseLastSyncDate:date];
}

/** Return whether the CIX service is online.
 
 @return Returns YES if the service is online, or NO if it is offline.
 */
+(BOOL)online
{
    return _onlineState;
}

/** Change the CIX service online state
 
 Call this method to control whether or not the CIX service synchronises
 with the API server. Setting the online state to NO will prevent any
 further synchronisation with the API server although changes will continue
 to be cached to the database. Setting the online state to YES will resume
 synchronisation.
 
 Note that this will not affect any online synchronisations in progress at the
 time the online state is changed from YES to NO. These will continue to run
 to completion.
 
 @param newOnline Set to YES to go online, or NO to go offline.
 */
+(void)setOnline:(BOOL)newOnline
{
   if (newOnline != _onlineState)
   {
       _onlineState = newOnline;

       NSThread * myThread = [[NSThread alloc] initWithTarget:self selector:@selector(runSync:) object:nil];
       [myThread start];
   }
}

/** Alters the task interval for the CIX service
 
 The new task interval should be a value expressed in milliseconds which is the
 duration between synchronisation attempts.
 
 If a synchronisation is in progress at the time the task interval is changed then
 the new interval will apply to the next synchronisation event.
 
 @param newInterval A new task interval, expressed in milliseconds.
 */
+(void)setTaskInterval:(int)newInterval
{
    _taskInterval = newInterval;
}

/** Initialises the CIX service task
 
 Call this function to initialise the background task that periodically
 synchronises the various collections with the API server. It is not required
 to call startTask but if you do not, some changes to the collections will only be
 persisted to the database and not synchronised with the API server.
 
 You can control the service task with two additional properties: setOnline:
 determines whether or not the task will synchronise since synchronisation will
 not occur if the CIX service is in offline mode. setTaskInterval: controls the
 frequency with which the task synchronises with the API server.
 */
+(void)startTask
{
    _uiTimer = [NSTimer timerWithTimeInterval:FirstRunInterval target:self selector:@selector(uiTimerFired:) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:_uiTimer forMode:NSRunLoopCommonModes];
}

/* Called when the synchronisation timer has fired.
 */
+(void)uiTimerFired:(NSTimer *)timer
{
    NSThread * myThread = [[NSThread alloc] initWithTarget:self selector:@selector(runSync:) object:nil];
    [myThread start];
    
    // We need to reschedule the timer each time since the interval after the first
    // run is longer.
    _uiTimer = [NSTimer timerWithTimeInterval:_taskInterval target:self selector:@selector(uiTimerFired:) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:_uiTimer forMode:NSRunLoopCommonModes];
}

/* Thread target to run a sync.
 */
+(void)runSync:(id)sender
{
    [self sync];
}

/* Perform a full synchronisation when the network state
 * changes or by the synchronisation duration specified by
 * the RunInterval variable.
 */
+(void)sync
{
    if (CIX.online)
    {
        dispatch_async(dispatch_get_main_queue(),^{
            NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
            [nc postNotificationName:MACIXSynchronisationStarted object:nil];
        });
        
        @try {
            [self.directoryCollection sync];
            [self.conversationCollection sync];
            [self.profileCollection sync];
            [self.folderCollection sync];
        }
        @catch (NSException *exception) {
            [CIX reportServerExceptions:__PRETTY_FUNCTION__ exception:exception];
        }
        
        dispatch_async(dispatch_get_main_queue(),^{
            NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
            [nc postNotificationName:MACIXSynchronisationCompleted object:nil];
        });
    }
}

/** Return the global count of unread messages

 @return The count of unread messages across all services
 */
+(NSInteger)totalUnread
{
    return _folderCollection.totalUnread + _conversationCollection.totalUnread;
}

/** Return the global count of unread priority messages
 
 @return The count of unread priority messages across all services
 */
+(NSInteger)totalUnreadPriority
{
    return _folderCollection.totalUnreadPriority + _conversationCollection.totalUnreadPriority;
}

/** Return the FolderCollection
 
 Initialises and returns a FolderCollection object for access to
 the collection subscribed forums and topics.
 
 @return A FolderCollection object.
 */
+(FolderCollection *)folderCollection
{
    if (_folderCollection == nil)
        _folderCollection = [[FolderCollection alloc] init];

    return _folderCollection;
}

/** Return the ProfileCollection
 
 Initialises and returns a ProfileCollection object for access to
 the collection of CIX member profiles.
 
 @return A ProfileCollection object.
 */
+(ProfileCollection *)profileCollection
{
    if (_profileCollection == nil)
        _profileCollection = [[ProfileCollection alloc] init];

    return _profileCollection;
}

/** Return the RuleCollection
 
 Initialises and returns a RuleCollection object for access to
 the collection of message rules.
 
 @return A RuleCollection object.
 */
+(RuleCollection *)ruleCollection
{
    if (_ruleCollection == nil)
        _ruleCollection = [[RuleCollection alloc] init];
    return _ruleCollection;
}

/** Return the DirectoryCollection
 
 Initialises and returns a DirectoryCollection object for access to
 the CIX forum directory.
 
 @return A DirectoryCollection object.
 */
+(DirectoryCollection *)directoryCollection
{
    if (_directoryCollection == nil)
    {
        _directoryCollection = [[DirectoryCollection alloc] init];
        [_directoryCollection setIndexingEnabled:NO];
    }
    return _directoryCollection;
}

/** Return the ConversationCollection
 
 Initialises and returns a ConversationCollection object for access to
 the private messaging system data.
 
 @return A ConversationCollection object.
 */
+(ConversationCollection *)conversationCollection
{
    if (_conversationCollection == nil)
        _conversationCollection = [[ConversationCollection alloc] init];
    
    return _conversationCollection;
}

/** Return a synchronisation object.
 
 Returns an unique object that can be used to synchronise access to the database
 from multiple threads. Use this as the argument to a @synchronize call. For
 example:
 
     @synchronized(CIX.DBLock) {
        ...Access database
     }
 
 The synchronisation object value is guaranteed to be unique in the same session
 but not across sessions. So do not store the synchronisation object anywhere.
 
 @return A synchronisation object
 */
+(id)DBLock
{
    return [self class];
}

/** Initialise the CIX service
 
 This method must be called before the CIX service methods can be used. It
 prepares the database for caching and initialises it if the database is
 missing.
 
 Note: the caller is responsible for ensuring that any folders on the path
 have been created in advance. If databasePath points to a non-existent folder
 then this function will fail.
 
 @param databasePath The path to the database file to use
 @return YES if the CIX service was successfully initialised, NO otherwise.
 */
+(BOOL)init:(NSString *)databasePath
{
    _db = [[FMDatabase alloc] initWithPath:databasePath];
    if (_db == nil || ![_db open])
        return NO;

    [LogFile.logFile writeLine:@"Opened database %@", databasePath];
    
    // Set flags on the db
    [_db setCrashOnErrors:YES];
    
    // Create remaining tables
    [Global create];
    [DirCategory create];
    [DirForum create];
    [Message create];
    [Folder create];
    [Conversation create];
    [MailMessage create];
    [Mugshot create];
    [Profile create];
    [Attachment create];
    
    // Set a date formatter than can store and parse in SQLite format
    [_db setDateFormat:[self dateFormatter]];
    
    // If database is pre-v6, do an upgrade
    _global = [[Global alloc] init];
    [Global upgrade];
    if (_global.databaseVersion < 2)
        [Message upgrade];
    if (_global.databaseVersion < 3)
        [DirForum upgrade];
    if (_global.databaseVersion < 4)
        [Conversation upgrade];
    if (_global.databaseVersion < 5)
        [Profile upgrade];
    if (_global.databaseVersion < 6)
        [Folder upgrade];
    [_global setDatabaseVersion:LatestDatabaseVersion];
    
    return YES;
}

/** Return the CIX date formatter
 
 This property returns an NSDateFormatter pre-initialised to parse date strings
 in CIX format. The CIX format is yyyy-MM-dd HH:mm:ss set to the current locale.
 
 @return An NSDateFormatter initialised to the standard CIX date string format.
 */
+(NSDateFormatter *)dateFormatter
{
    if (_sqlDateFormat == nil)
    {
        _sqlDateFormat = [[NSDateFormatter alloc] init];
        [_sqlDateFormat setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
        [_sqlDateFormat setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        [_sqlDateFormat setFormatterBehavior:NSDateFormatterBehavior10_4];
        [_sqlDateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    }
    return _sqlDateFormat;
}

/** Return the standard CIX date formatter
 
 @return An NSDateFormatter for parsing or displaying CIX style dates
 */
+(NSDateFormatter *)CIXDateFormatter
{
    if (_cixDateFormat == nil)
    {
        _cixDateFormat = [[NSDateFormatter alloc] init];
        [_cixDateFormat setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]];
        [_cixDateFormat setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        [_cixDateFormat setFormatterBehavior:NSDateFormatterBehavior10_4];
        [_cixDateFormat setDateFormat:@"dd/MM/yyyy HH:mm:ss"];
    }
    return _cixDateFormat;
}

/** Close the CIX service.
 
 After calling the close method, no further requests can be issued until a corresponding
 call to the init method is made. Any existing requests in progress will fail.
 */
+(void)close
{
    [CIX.folderCollection closeSync];
    
    if (_uiTimer != nil)
    {
        [_uiTimer invalidate];
        _uiTimer = nil;
    }
    if (_db != nil)
    {
        [_db close];
        _db = nil;
    }
    _userAccountType = AccountTypeUnknown;
}

/** Authenticate the specified username and password.
 
 The authenticate method contacts the CIX server, passing through the specified username
 and password and verifies that is successfully authenticates. On completion, a
 MAUserAccountTypeCompleted notification is posted with the type of the users account.
 
 Because the function runs asynchronously, the caller must subscribe to the notification
 to obtain the result of the authentication. The callback is issued even if an error occurs
 in which case the account type will be nil.
 
 @param username The user name to authenticate
 @param password The password to authenticate
 */
+(void)authenticate:(NSString *)username withPassword:(NSString *)password
{
    NSURLRequest * request = [APIRequest getWithCredentials:@"user/account" username:username password:password];
    if (request != nil)
    {
        NSURLSession * session = [NSURLSession sharedSession];
        NSURLSessionDataTask * task = [session dataTaskWithRequest:request
                                                 completionHandler:
                                       ^(NSData *data, NSURLResponse *response, NSError *error) {
                                           NSString * accountType = nil;
                                           if (error == nil)
                                           {
                                               NSString * responseString = [[NSString alloc] initWithBytes:data.bytes length:data.length encoding:NSUTF8StringEncoding];
                                               JSONModelError * jsonError = nil;
                                               
                                               J_Account * account = [[J_Account alloc] initWithString:responseString error:&jsonError];
                                               if (jsonError == nil)
                                               {
                                                   accountType = [account Type];
                                                   if ([accountType hasPrefix:@"version"])
                                                       accountType = nil;
                                                   else
                                                   {
                                                       NSDictionary * map = @{@"ICA-SUT" : @AccountTypeFull,
                                                                              @"ICA-OUT" : @AccountTypeFull,
                                                                              @"OUT" :     @AccountTypeFull,
                                                                              @"CCA" :     @AccountTypeFull,
                                                                              @"BASIC" :   @AccountTypeBasic
                                                                              };
                                                       NSString * accountTypeCode = [map valueForKey:accountType];
                                                       if (accountTypeCode != nil)
                                                           _userAccountType = [accountTypeCode intValue];
                                                   }
                                               }
                                           }
                                           
                                           // Callback occurs even if there was an error in which case the
                                           // accountType is nil.
                                           dispatch_async(dispatch_get_main_queue(),^{
                                               NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
                                               [nc postNotificationName:MAUserAuthenticationCompleted object:accountType];
                                           });
                                       }];
        
        [task resume];
    }
}

/** Retrieve the list of online users
 
 Fires a MAOnlineUsersRefreshed notification when the list has been retrieved.
 */
+(void)refreshOnlineUsers
{
    NSURLRequest * request = [APIRequest get:@"user/who"];
    if (request != nil)
    {
        [LogFile.logFile writeLine:@"Retrieving list of online users"];
        
        NSURLSession * session = [NSURLSession sharedSession];
        NSURLSessionDataTask * task = [session dataTaskWithRequest:request
                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                        {
                                           if (error == nil)
                                           {
                                               Response * resp = [[Response alloc] initWithObject:self];

                                               JSONModelError * jsonError = nil;
                                                   
                                               J_Whos * whos = [[J_Whos alloc] initWithData:data error:&jsonError];
                                               if (jsonError != nil)
                                                   resp.errorCode = CCResponse_NoSuchForum;
                                               else
                                               {
                                                   NSMutableArray * onlineUsers = [NSMutableArray array];
                                                   for (J_Who * user in whos.Users)
                                                       [onlineUsers addObject:user.Name];
                                                   resp.object = onlineUsers;
                                               }
                                               
                                               // Notify interested parties that the list of online users
                                               // has changed.
                                               dispatch_async(dispatch_get_main_queue(),^{
                                                   NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
                                                   [nc postNotificationName:MAOnlineUsersRefreshed object:resp];
                                               });
                                           }
                                       }];
        [task resume];
    }
}

/** Return the authenticated user account type
 
 @return The user account type
 */
+(int)userAccountType
{
    return _userAccountType;
}

/** Make a request to retrieve the user's account type from the API
 
 This request occurs asynchronously and the caller is notified via the MAUserAccountTypeChanged
 notification. The notification will not occur if an error is detected due to invalid account
 credentials, network errors or malformed responses.
 */
+(void)refreshUserAccount
{
    if (CIX.online)
        [self authenticate:CIX.username withPassword:CIX.password];
}

/* Compact the database.
 */
+(void)compactDatabase
{
    if (CIX.DB != nil)
        [CIX.DB executeStatements:@"vacuum"];
}

// Handle server exceptions and log these with details. For HTTP authentication errors
// we also invoke the authentication failed event handler.
+(void)reportServerExceptions:(const char *)methodName exception:(NSException *)exception
{
    [LogFile.logFile writeLine:@"%s : Caught exception %@", methodName, [exception description]];
}

// Handle server errors and log these with details.
+(void)reportServerErrors:(const char *)methodName error:(NSError *)error
{
    [LogFile.logFile writeLine:@"%s : Caught error %@", methodName, [error description]];
}
@end
