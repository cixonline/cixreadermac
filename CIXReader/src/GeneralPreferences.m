//
//  GeneralPreferences.m
//  CIXReader
//
//  Created by Steve Palmer on 21/09/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "GeneralPreferences.h"
#import "Preferences.h"
#import "CIX.h"
#import "PopUpButtonExtensions.h"

// Private functions
@interface GeneralPreferences (Private)
-(void)initializePreferences;
@end

@implementation GeneralPreferences

static NSDictionary * cacheListOptions = nil;

/* Initialize the class
 */
-(id)initWithObject:(id)data
{
    return [super initWithNibName:@"GeneralPreferences" bundle:nil];
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

    [startOffline setState:[prefs startOffline] ? NSOnState : NSOffState];
    [startAtHomePage setState:[prefs startAtHomePage] ? NSOnState : NSOffState];
    
    [archiveLogFiles setState:[prefs archiveLogFile] ? NSOnState : NSOffState];
    [enableLogFiles setState:[prefs enableLogFile] ? NSOnState : NSOffState];
    
    cacheListOptions =  @{@"Never"  : @(0),
                          @"Daily"  : @(1),
                          @"Weekly" : @(7)
                          };

    [cleanUpCacheList removeAllItems];
    for (NSString * title in cacheListOptions.allKeys) {
        int value = [cacheListOptions[title] intValue];
        [cleanUpCacheList addItemWithTag:title tag:value];
    }
    [cleanUpCacheList selectItemWithTag:prefs.cacheCleanUpFrequency];
    
    [appBadgeMatrix selectCellWithTag:prefs.appBadgeMode];
}

-(IBAction)changeAppBadgeMode:(id)sender
{
    [[Preferences standardPreferences] setAppBadgeMode:(AppBadge)[appBadgeMatrix selectedTag]];
}

/* Toggle enabling log file.
*/
-(IBAction)changeEnableLogFiles:(id)sender
{
    BOOL flag = [sender state] == NSOnState;
    [[Preferences standardPreferences] setEnableLogFile:flag];
}

/* Toggle log file archiving.
 */
-(IBAction)changeArchiveLogFiles:(id)sender
{
    BOOL flag = [sender state] == NSOnState;
    [[Preferences standardPreferences] setArchiveLogFile:flag];
}

/* Open the log file
 */
-(IBAction)handleOpenLogFile:(id)sender
{
    NSString * logFilePath = [LogFile.logFile path];
    [[NSWorkspace sharedWorkspace] openFile:logFilePath];
}

/* Toggle option whether to start CIXReader offline
 */
-(IBAction)changeStartOffline:(id)sender
{
    BOOL flag = [sender state] == NSOnState;
    [[Preferences standardPreferences] setStartOffline:flag];
}

/* Toggle the option whether to start CIXReader at the home page
 */
-(IBAction)changeStartAtHomePage:(id)sender
{
    BOOL flag = [sender state] == NSOnState;
    [[Preferences standardPreferences] setStartAtHomePage:flag];
}

/* Change cache clean up frequency
 */
-(IBAction)cleanUpCacheChanged:(id)sender
{
    NSInteger value = [cleanUpCacheList selectedTag];
    [[Preferences standardPreferences] setCacheCleanUpFrequency:value];
}

/* Mark all messages in the db as read
 * This is a Preferences button because it is pretty risky as there's no undo. If we eventually
 * add undo support, as in Vienna, we can move this to a menu.
 */
-(IBAction)handleMarkAllRead:(id)sender
{
    NSAlert * alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:NSLocalizedString(@"No", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"Yes", nil)];
    [alert setMessageText:NSLocalizedString(@"Mark All Read", nil)];
    [alert setInformativeText:NSLocalizedString(@"All messages in all forums will be marked read with the exception of read locked messages. Are you sure?", nil)];
    [alert setAlertStyle:NSAlertStyleWarning];
    
    NSModalResponse returnCode = [alert runModal];

    if (returnCode == NSAlertSecondButtonReturn)
    {
        [CIX.folderCollection markAllRead];
    }
}
@end
