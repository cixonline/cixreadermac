//
//  UpdatePreferences.m
//  CIXReader
//
//  Created by Steve Palmer on 21/09/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "UpdatePreferences.h"
#import "Preferences.h"
#import "LogFile.h"

// Private functions
@interface UpdatePreferences (Private)
-(void)initializePreferences;
@end

@implementation UpdatePreferences

/* Initialize the class
 */
-(id)initWithObject:(id)data
{
    return [super initWithNibName:@"UpdatePreferences" bundle:nil];
}

/* First time window load initialisation. Since preferences could potentially be
 * changed while the Preferences window is closed, initialise the controls in the
 * initializePreferences function instead.
 */
-(void)awakeFromNib
{
    if (!_didInitialise)
    {
        [self initializePreferences];
        _didInitialise = YES;
    }
}

/* Set the preference settings from the user defaults.
 */
-(void)initializePreferences
{
    Preferences * prefs = [Preferences standardPreferences];
    [checkForUpdates setState:[prefs checkForUpdates] ? NSOnState : NSOffState];
    [useBetaReleases setState:[prefs useBeta] ? NSOnState : NSOffState];
}

/* Toggle whether we automatically check for updates
 */
-(IBAction)changeCheckForUpdates:(id)sender
{
    BOOL flag = [sender state] == NSOnState;
    [[Preferences standardPreferences] setCheckForUpdates:flag];
}

/* Toggle using beta releases.
 */
-(IBAction)changeUseBetaReleases:(id)sender
{
    BOOL flag = [sender state] == NSOnState;
    [[Preferences standardPreferences] setUseBeta:flag];
}
@end
