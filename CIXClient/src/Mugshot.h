//
//  Mugshot.h
//  CIXClient
//
//  Created by Steve Palmer on 27/08/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "TableBase.h"

/** The Mugshot class provides access to CIX user mugshots
 
 A mugshot is a small, typically 100x100, graphic image that represents the user. This
 is also typically known as an avatar. The use of a mugshot is optional and some users may
 choose not to have one. Mugshots are accessed via the API server so the same mugshot can
 be shared across multiple client platforms.
 
 The Mugshot class provides the following functionality:
 
 * Given a CIX username, return their associated mugshot.
 * Replace the authenticated users own mugshot and upload it to the API server.
 
 You cannot change the mugshot for any user other than the authenticated user. Such
 changes will not be persisted.
 
 Changes to mugshots are announced via MAUserMugshotChanged notification. Interested
 parties should subscribe to the notification to update mugshots in the UI.
 */
@interface Mugshot : TableBase

/** Returns the username
 
 @return The username to which the mugshot belongs
 */
@property NSString * username;

/** Returns the mugshot image
 
 @return The NSImage representing the mugshot image.
 */
@property ImageClass * image;

@property BOOL pending;

// Accessors
+(Mugshot *)mugshotForUser:(NSString *)username;
+(Mugshot *)mugshotForUser:(NSString *)username withRefresh:(BOOL)refresh;
-(void)update;
-(void)refresh;
@end
