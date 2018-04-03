//
//  Profile.m
//  CIXClient
//
//  Created by Steve Palmer on 27/08/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "CIX.h"
#import "Profile_Private.h"
#import "StringExtensions.h"
#import "ProfileSet.h"
#import "ProfileSmall.h"

@implementation Profile

/** Return the user's friendly name
 
 The user's friendly name is the most visible name. By default it is
 their full name but if none is provided, it will be their username.
 Since all users have a username, this method is guaranteed to return
 a non-empty result.
 
 @return The user's friendly name
 */
-(NSString *)friendlyName
{
    return IsEmpty(_fullname) ? _username : _fullname;
}

/** Return the profile for the specified user
 
 Given a username, this method returns the Profile object for that user. The result
 of the request may trigger an asynchronous update to retrieve the profile from the
 API server if none is found locally. In this instance, a Profile is returned with
 just the username and the caller should subscribe to the MAUserProfileChanged
 notification to be notified when the full profile has been retrieved.
 
 @param username The name of the user for which the profile is requested.
 @return A Profile object initialised with the profile for the user
 */
+(Profile *)profileForUser:(NSString *)username
{
    ProfileCollection * prc = CIX.profileCollection;
    NSString * fixedUsername = [username lowercaseString];
    Profile * profile = [prc get:fixedUsername];
    if (profile == nil)
    {
        profile = [[Profile alloc] init];
        profile.username = fixedUsername;
        [prc add:profile];
    }
    return profile;
}

/** Update this profile in the database
 
 This method only works if the profile username is the authenticated user.
 You cannot change the profile for any other user!
 
 This method should be called if the profile details have been altered and the
 changes should be committed. To avoid excessive updates, the responsibility
 for committing the changes is left to the caller. If the API server is online,
 the changes are also asynchronously sent to the server.
 
 On completion of the update, a MAUserProfileChanged notification is posted
 with a Response object where the object field is set to the Profile and the
 errorCode field is set to CCResponse_NoError.
 */
-(void)update
{
    self.pending = YES;
    
    [self save];
    
    // Alert interested parties about this change to the profile
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:MAUserProfileChanged object:[Response responseWithObject:self andError:CCResponse_NoError]];
    
    // Update on the server
    [self sync];
}

/** Refresh the profile from the server
 
 Call this method to retrieve or refresh the profile from the server.
 
 Call this method to update the profile from the server. On completion,
 a MAUserProfileChanged notification is posted with a Response object where
 the object field is set to the Profile and the errorCode field is set to
 the appropriate error code:
 
 * CCResponse_NoError - the profile was successfully retrieved
 * CCResponse_ServerError - a generic error occurred
 * CCResponse_Offline - the server is offline.
 * CCResponse_NoSuchUser - no profile was found for the user

 */
-(void)refresh
{
    if (!CIX.online)
    {
        NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:MAUserProfileChanged object:[Response responseWithObject:self andError:CCResponse_Offline]];
        return;
    }

    // Different URL for authenticated user because the Email field is blank if you're not
    // the authenticated user.
    NSString * profileUrl = [_username isEqualToString:CIX.username] ? @"user/profile" : [NSString stringWithFormat:@"user/%@/profile", _username];
    NSURLRequest * profileRequest = [APIRequest get:profileUrl];
    if (profileRequest != nil)
    {
        NSURLSession * session = [NSURLSession sharedSession];
        NSURLSessionDataTask * task = [session dataTaskWithRequest:profileRequest
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
                                               NSString * responseString = [[NSString alloc] initWithBytes:data.bytes length:data.length encoding:NSUTF8StringEncoding];
                                               JSONModelError * jsonError = nil;
                                               
                                               J_ProfileSmall * smallProfile = [[J_ProfileSmall alloc] initWithString:responseString error:&jsonError];
                                               if (jsonError != nil)
                                                   resp.errorCode = CCResponse_NoSuchUser;
                                               else
                                               {
                                                   NSDictionary * sexMap = @{@"0" : @"m",
                                                                             @"1" : @"f",
                                                                             @"2" : @"u"};
                                                   [self setSex:[sexMap valueForKey:smallProfile.Sex]];
                                                   [self setFullname:[NSString stringWithFormat:@"%@ %@", smallProfile.Fname, smallProfile.Sname]];
                                                   [self setLocation:smallProfile.Location];
                                                   [self setLastOn:[smallProfile.LastOn fromJSONDate]];
                                                   [self setEMailAddress:smallProfile.Email];
                                                   [self setFirstOn:[smallProfile.FirstOn fromJSONDate]];
                                                   [self setLastPost:[smallProfile.LastPost fromJSONDate]];
                                                   [self setFlags:smallProfile.Flags];
                                                   [self setPending:NO];
                                                   [self save];
                                                   
                                                   LogFile * log = LogFile.logFile;
                                                   [log writeLine:@"Profile for %@ retrieved from server", self->_username];
                                               }
                                           }
                                           
                                           // Alert interested parties about this change to the profile
                                           dispatch_async(dispatch_get_main_queue(),^{
                                               NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
                                               [nc postNotificationName:MAUserProfileChanged object:resp];
                                           });
                                       }];
        [task resume];
    }

    NSString * resumeUrl = [NSString stringWithFormat:@"user/%@/resume", _username];
    NSURLRequest * resumeRequest = [APIRequest get:resumeUrl];
    if (resumeRequest != nil)
    {
        NSURLSession * session = [NSURLSession sharedSession];
        NSURLSessionDataTask * task = [session dataTaskWithRequest:resumeRequest
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
                                               NSString * responseString = [[NSString alloc] initWithBytes:data.bytes length:data.length encoding:NSUTF8StringEncoding];
                                               if (responseString == nil || [responseString hasPrefix:@"<error "])
                                                   resp.errorCode = CCResponse_NoSuchUser;
                                               else
                                               {
                                                   responseString = [responseString trimWithCharacter:'\"'];
                                                   responseString = [responseString fromJSONString];
                                                   [self setAbout:[responseString unquoteAttributes]];
                                                   [self save];
                                                   
                                                   LogFile * log = LogFile.logFile;
                                                   [log writeLine:@"Resume for %@ retrieved from server", self->_username];
                                               }
                                           }
                                           
                                           // Alert interested parties about this change to the resume
                                           dispatch_async(dispatch_get_main_queue(),^{
                                               NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
                                               [nc postNotificationName:MAUserProfileChanged object:resp];
                                           });
                                       }];
        [task resume];
    }
}

/* Synchronise changes to this profile with the server
 * This method synchronises the authenticated users profile with the server. If
 * does nothing if the profile is not for the authenticated user.
 */
-(void)sync
{
    if (!CIX.online)
        return;
    
    // Cannot sync someone else's profile!
    if (![_username isEqualToString:CIX.username])
        return;

    NSArray * splitStrings = [self splitFullName:self.fullname];

    LogFile * log = LogFile.logFile;
    [log writeLine:@"Uploading profile and resume for %@ to server", CIX.username];

    J_ProfileSet * newProfileSmall = [[J_ProfileSet alloc] init];
    [newProfileSmall setFname:splitStrings[0]];
    [newProfileSmall setSname:splitStrings[1]];
    [newProfileSmall setLocation:self.location];
    [newProfileSmall setEmail:self.eMailAddress];
    [newProfileSmall setSex:self.sex];
    [newProfileSmall setFlags:self.flags];
    
    NSURLRequest * profileRequest = [APIRequest post:@"user/setprofile" withData:newProfileSmall];
    if (profileRequest != nil)
    {
        NSURLSession * session = [NSURLSession sharedSession];
        NSURLSessionDataTask * task = [session dataTaskWithRequest:profileRequest
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
                                                       [log writeLine:@"Profile successfully uploaded"];
                                               }
                                           }
                                       }];
        [task resume];
    }

    NSURLRequest * resumeRequest = [APIRequest post:@"user/setresume" withData:self.about];
    if (resumeRequest != nil)
    {
        NSURLSession * session = [NSURLSession sharedSession];
        NSURLSessionDataTask * task = [session dataTaskWithRequest:resumeRequest
                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                       {
                                           if (error != nil)
                                               [CIX reportServerErrors:__PRETTY_FUNCTION__ error:error];
                                           else
                                           {
                                               if (data != nil)
                                               {
                                                   NSString * responseString = [APIRequest responseTextFromData:data];
                                                   if ([responseString isEqualToString:@"True"])
                                                   {
                                                       [log writeLine:@"Resume successfully uploaded"];
                                                       [self setPending:NO];
                                                       [self save];
                                                   }
                                               }
                                           }
                                       }];
        [task resume];
    }
}

/* Split a full name into a first name and surname portion. A total of two parts are
 * always returned in the array, and the surname is left blank if only one name is
 * specified. Any middle names are considered part of the surname.
 */
-(NSArray *)splitFullName:(NSString *)fullname
{
    NSUInteger splitPoint = [fullname indexOfCharacterInString:' ' afterIndex:0];
    if (splitPoint == NSNotFound)
        return @[ fullname, @"" ];

    NSString * forename = [[fullname substringToIndex:splitPoint] trim];
    NSString * surname = [[fullname substringFromIndex:splitPoint] trim];
    return @[ forename, surname ];
}

/* Call superclass to get description format
 */
-(NSString *)description
{
    return [super description];
}
@end
