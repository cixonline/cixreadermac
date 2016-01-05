//
//  CIX.h
//  CIXClient
//
//  Created by Steve Palmer on 31/07/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "APIRequest.h"
#import "FolderCollection.h"
#import "ProfileCollection.h"
#import "DirectoryCollection.h"
#import "ConversationCollection.h"
#import "MessageCollection.h"
#import "RuleCollection.h"
#import "Constants.h"
#import "Mugshot.h"
#import "LogFile.h"
#import "Response.h"

#define AccountTypeUnknown      -1
#define AccountTypeFull         0
#define AccountTypeBasic        1

#define LatestDatabaseVersion   6

@class FMDatabase;

/** The CIX service class
 
 The CIX service class provides direct access to the collections of tables
 which contain the cached data retrieved from the API server. The following
 functionality is exposed:
 
 * Setting the CIX username and password for access to the users account.
 * Changing the default home folder for the database.
 * Initialising the database with its default contents.
 * Initialising the service task for background synchronisation.
 * Access to the table collections.
 * Authenticating a user account asynchronously.
 
 The CIX service class automatically deals with synchronisation and update
 to the database requiring the caller to simply access the data through the
 table collections and calling the appropriate update methods to commit
 changes to the database cache.
 */
@interface CIX : NSObject

// Accessors
+(FMDatabase *)DB;
+(id)DBLock;
+(void)compactDatabase;
+(FolderCollection *)folderCollection;
+(ProfileCollection *)profileCollection;
+(DirectoryCollection *)directoryCollection;
+(ConversationCollection *)conversationCollection;
+(RuleCollection *)ruleCollection;
+(void)setHomeFolder:(NSString *)newHomeFolder;
+(NSString *)homeFolder;
+(void)setUsername:(NSString *)newUsername;
+(NSString *)username;
+(BOOL)init:(NSString *)databasePath;
+(NSInteger)totalUnread;
+(NSInteger)totalUnreadPriority;
+(void)close;
+(BOOL)online;
+(void)startTask;
+(void)setTaskInterval:(int)newInterval;
+(NSDate *)lastSyncDate;
+(void)setLastSyncDate:(NSDate *)date;
+(void)setOnline:(BOOL)newOnline;
+(void)reportServerExceptions:(const char *)methodName exception:(NSException *)exception;
+(void)reportServerErrors:(const char *)methodName error:(NSError *)error;
+(NSDateFormatter *)dateFormatter;
+(NSDateFormatter *)CIXDateFormatter;
+(void)authenticate:(NSString *)username withPassword:(NSString *)password;
+(int)userAccountType;
+(void)refreshOnlineUsers;
@end

@interface CIX (CIXSecurity)
+(void)setPassword:(NSString *)newPassword;
+(NSString *)password;
@end
