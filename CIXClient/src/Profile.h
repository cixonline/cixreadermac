//
//  Profile.h
//  CIXClient
//
//  Created by Steve Palmer on 27/08/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "TableBase.h"

/** The Profile class provides access to CIX user profiles
 
 A profile is a collection of user's public details all of which are optional
 and are not often provided but can include their full name, e-mail address,
 location and even sex.
 
 The Profile class provides the following functionality:
 
 * Given a CIX username, return their profile.
 * Replace the authenticated users own profile and upload it to the API server.
 
 You cannot change the profile for any user other than the authenticated user. Such
 changes will not be persisted.
 
 Changes to profiles are announced via MAUserProfileChanged notification. Interested
 parties should subscribe to the notification to be alerted to changes.
 */
@interface Profile : TableBase

@property ID_type ID;
@property NSString * username;
@property NSString * eMailAddress;
@property NSString * fullname;
@property NSDate * lastOn;
@property NSDate * firstOn;
@property NSDate * lastPost;
@property NSString * location;
@property NSString * sex;
@property NSString * about;
@property BOOL pending;
@property int flags;

// Accessors
+(Profile *)profileForUser:(NSString *)username;
-(void)update;
-(void)refresh;
-(NSString *)friendlyName;
@end
