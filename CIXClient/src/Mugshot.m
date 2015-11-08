//
//  Mugshot.m
//  CIXClient
//
//  Created by Steve Palmer on 27/08/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "CIX.h"
#import "FMDatabase.h"
#import "Mugshot_Private.h"
#import "ImageExtensions.h"
#import "StringExtensions.h"

static ImageClass * defaultUserImage = nil;
static NSMutableDictionary * _cache = nil;

@implementation Mugshot

/* Override to specify that the username is the identity column.
 */
+(NSString *)identityColumn
{
    return @"username";
}

/* Return YES to force an index to be built on this table using the identity column.
 */
+(BOOL)requiresIndex
{
    return YES;
}

/** Return the mugshot for the specified user.
 
 Given a username, this method returns the Mugshot object for that user. The result
 of the request may trigger an asynchronous update to retrieve the mugshot from the
 API server if none is found locally. In this instance, a Mugshot is returned with
 the default stock mugshot and the caller should subscribe to the MAUserMugshotChanged
 notification to be informed when the actual mugshot has been retrieved.
 
 @param username The name of the user for which the mugshot is requested.
 @return A Mugshot object initialised with the mugshot image for the user
 */
+(Mugshot *)mugshotForUser:(NSString *)username
{
    return [self mugshotForUser:username withRefresh:YES];
}

/** Return the mugshot for the specified user.
 
 Given a username, this method returns the Mugshot object for that user if it
 is in the cache, or otherwise returns the default mugshot.
 
 @param username The name of the user for which the mugshot is requested.
 @return A Mugshot object initialised with the mugshot image for the user
 */
+(Mugshot *)mugshotForUser:(NSString *)username withRefresh:(BOOL)refresh
{
    Mugshot * mugshot = nil;
    
    if (username != nil)
    {
        if (_cache == nil)
        _cache = [NSMutableDictionary dictionary];
        
        NSString * fixedUsername = [username lowercaseString];
        mugshot = [_cache objectForKey:fixedUsername];
        if (mugshot == nil)
        {
            NSString * query = [NSString stringWithFormat:@" where Username='%@'", fixedUsername];
            NSArray * results = [Mugshot allRowsWithQuery:query];
            
            if (results.count > 0)
                mugshot = results[0];
            else
            {
                mugshot = [[Mugshot alloc] init];
                mugshot.username = username;
                mugshot.image = [Mugshot defaultMugshot];
                
                if (refresh)
                    [mugshot refresh];
            }
            _cache[fixedUsername] = mugshot;
        }
    }
    return mugshot;
}

/** Update this mugshot in the database.
 
 This method only works if the mugshot username is the authenticated user.
 You cannot change the mugshot for any other user!
 
 This method should be called if the mugshot image has been altered and the 
 changes should be committed. To avoid excessive updates, the responsibility 
 for committing the changes is left to the caller. If the API server is online,
 the changes are also asynchronously sent to the server.
 
 On completion of the update, a MAUserMugshotChanged notification is posted 
 with a Response object where the object field is set to the Mugshot and the 
 errorCode field is set to CCResponse_NoError.
 */
-(void)update
{
    if ([_username isEqualToString:CIX.username])
    {
        self.pending = YES;
        
        [self save];
        
        // Alert interested parties about this change to the mugshot
        NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:MAUserMugshotChanged object:[Response responseWithObject:self andError:CCResponse_NoError]];
        
        // Update on the server
        [self sync];
    }
}

/** Refresh the mugshot from the server
 
 Call this method to update the mugshot from the server. On completion,
 a MAUserMugshotChanged notification is posted with a Response object where
 the object field is set to the Mugshot and the errorCode field is set to
 the appropriate error code:
 
 * CCResponse_NoError - the mugshot was successfully retrieved
 * CCResponse_ServerError - a generic error occurred
 * CCResponse_Offline - the server is offline.
 * CCResponse_NoSuchUser - no mugshot was found for the user
 
 */
-(void)refresh
{
    if (!CIX.online)
    {
        NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:MAUserMugshotChanged object:[Response responseWithObject:self andError:CCResponse_Offline]];
        return;
    }

    NSString * url = [NSString stringWithFormat:@"user/%@/mugshot", _username];
    NSURLRequest * request = [APIRequest get:url];
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
                                           else if (data == nil || data.length == 0)
                                               resp.errorCode = CCResponse_NoSuchUser;
                                           else
                                           {
                                               self.image = [[[ImageClass alloc] initWithData:data] resize:CGSizeMake(100, 100)];
                                               if (self.image == nil)
                                                   self.image = [Mugshot defaultMugshot];
                                               self.pending = NO;
                                               [self save];
                                               
                                               LogFile * log = LogFile.logFile;
                                               [log writeLine:@"Mugshot for %@ updated from server", _username];
                                           }
                                           
                                           // Alert interested parties about this change to the mugshot
                                           dispatch_async(dispatch_get_main_queue(),^{
                                               NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
                                               [nc postNotificationName:MAUserMugshotChanged object:resp];
                                           });
                                       }];
        [task resume];
    }
}

/* Save these changes to the database.
 */
-(void)save
{
    @synchronized(CIX.DBLock) {
        NSData * pngData = [self.image JFIFData:1.0];
        
        [CIX.DB executeUpdate:@"insert or replace into Mugshot (Username, Image, Pending) values (?, ?, ?)"
         withArgumentsInArray:@[ self.username,
                                 pngData,
                                 [@(self.pending) stringValue] ]];
    }
}

/* Synchronise this mugshot with the server
 * This method synchronises the authenticated user's mugshot with the server.
 */
-(void)sync
{
    if (!CIX.online)
        return;
    
    // Cannot sync someone else's mugshot!
    if (![_username isEqualToString:CIX.username])
        return;

    LogFile * log = LogFile.logFile;
    [log writeLine:@"Uploading mugshot for %@ to server", _username];

    NSURLRequest * request = [APIRequest post:@"user/setmugshot" withData:_image];
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
                                                   if (responseString != nil)
                                                   {
                                                       if ([responseString isEqualToString:@"Success"])
                                                       {
                                                           [log writeLine:@"Mugshot successfully uploaded"];
                                                           self.pending = NO;
                                                           [self save];
                                                       }
                                                   }
                                               }
                                           }
                                       }];
        [task resume];

    }
}


/* Return the default mugshot from the framework resource file and
 * cache it for ready access.
 */
+(ImageClass *)defaultMugshot
{
    if (defaultUserImage == nil)
    {
        NSBundle *frameworkBundle = [NSBundle bundleForClass:[Mugshot class]];
        NSString *imagePath = [frameworkBundle pathForResource:@"defaultUser" ofType:@"tiff"];
        defaultUserImage = [[ImageClass alloc] initWithContentsOfFile:imagePath];
    }
    return defaultUserImage;
}

/* Call superclass to get description format
 */
-(NSString *)description
{
    return [super description];
}
@end
