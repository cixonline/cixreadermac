//
//  ProfileCollection.m
//  CIXClient
//
//  Created by Steve Palmer on 27/08/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "CIX.h"
#import "Mugshot_Private.h"
#import "Profile_Private.h"

@implementation ProfileCollection

/* Synchronise the profile collection, updating any changes to the local
 * profile and resume that was made offline to the server.
 */
-(void)sync
{
    if (CIX.online)
    {
        @try {
            Profile * selfProfile = [Profile profileForUser:CIX.username];
            if (selfProfile != nil && selfProfile.pending)
                [selfProfile sync];
            
            Mugshot * selfMugshot = [Mugshot mugshotForUser:CIX.username];
            if (selfMugshot != nil && [selfMugshot pending])
                [selfMugshot sync];
        }
        @catch (NSException *exception) {
            [CIX reportServerExceptions:__PRETTY_FUNCTION__ exception:exception];
        }
    }
}

/* Return a immutable list of all profiles.
 */
-(NSMutableArray *)profiles
{
    if (_profiles == nil)
        _profiles = [[NSMutableArray alloc] initWithArray:[Profile allRows]];

    return _profiles;
}

/* Return the total number of profiles in the collection.
 */
-(NSUInteger)countOfProfiles
{
    return [self.profiles count];
}

/* Return the profile at the specified index.
 */
-(id)objectInProfilesAtIndex:(NSUInteger)index
{
    return self.profiles[index];
}

/* Add a new profile to the database.
 */
-(void)add:(Profile *)profile
{
    [self.profiles addObject:profile];
}

/* Look up a profile for the specified user.
 */
-(Profile *)get:(NSString *)username
{
    for (Profile * profile in self.profiles) {
        if ([profile.username isEqualToString:username])
             return profile;
    }
    return nil;
}

/* Support fast enumeration on the profiles list.
 */
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])stackbuf count:(NSUInteger)len
{
    return [self.profiles countByEnumeratingWithState:state objects:stackbuf count:len];
}
@end
