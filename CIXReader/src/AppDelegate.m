//
//  AppDelegate.m
//  CIXReader
//
//  Created by Steve Palmer on 30/07/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "AppDelegate.h"
#import "Preferences.h"
#import "JoinForumController.h"
#import "EULAController.h"
#import "LoginController.h"
#import "ProfileController.h"
#import "Extensions.h"
#import "CRToolbarItem.h"
#import "Reachability.h"
#import "MailEditor.h"
#import "ForumsView.h"
#import "DirectoryView.h"
#import "TopicView.h"
#import "MailView.h"
#import "WelcomeView.h"
#import "WindowCollection.h"
#import "ImageProtocol.h"
#import "AttachProtocol.h"
#import "Sparkle/Sparkle.h"

#define NSApplicationRelaunchDaemon @"relaunch"

@implementation AppDelegate

@synthesize articleMenu;
@synthesize folderMenu;

/* Class instance initialisation.
 */
-(id)init
{
    if ((self = [super init]) != nil)
        _isStatusBarVisible = YES;
    return self;
}

/* Allow full screen support
 */
-(void)awakeFromNib
{
    MailView * messageView = [[MailView alloc] init];
    DirectoryView * directoryView = [[DirectoryView alloc] init];
    ForumsView * forumsView = [[ForumsView alloc] init];
    TopicView * topicView = [[TopicView alloc] init];
    WelcomeView * welcomeView = [[WelcomeView alloc] init];
    
    // allViews is a collection of all views keyed by their view ID
    _allViews = @{  @(AppViewMail)      : messageView,
                    @(AppViewDirectory) : directoryView,
                    @(AppViewForum)     : forumsView,
                    @(AppViewTopic)     : topicView,
                    @(AppViewWelcome)   : welcomeView
                    };
    
    [mainWindow setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
}

/* Handle CIXReader launched by clicking a link outside. Save the
 * launch address for use when applicationDidFinishLaunching completes.
 */
-(void)setLaunchAddress:(NSString *)linkPath
{
    _launchAddress = linkPath;
}

/* Run the logic after the application completed launching.
 */
-(void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self initialiseLogFile];
    
    LogFile * logFile = LogFile.logFile;
    [logFile writeLine:@"%@ %@ started", [self applicationTitle], [self applicationVersion]];
    
    if (![self initialiseDatabase])
    {
        [NSApp terminate:self];
        return;
    }
    
    // Get notified of network state changes
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    [reachability startNotifier];
    
    [ImageProtocol registerProtocol];
    [AttachProtocol registerProtocol];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];
    [nc addObserver:self selector:@selector(handleShowStatusBar:) name:MA_Notify_StatusBarChanged object:nil];
    [nc addObserver:self selector:@selector(handleSynchronisationStarted:) name:MACIXSynchronisationStarted object:nil];
    [nc addObserver:self selector:@selector(handleSynchronisationCompleted:) name:MACIXSynchronisationCompleted object:nil];
    [nc addObserver:self selector:@selector(updateApplicationBadge:) name:MAFolderRefreshed object:nil];
    [nc addObserver:self selector:@selector(updateApplicationBadge:) name:MAFolderUpdated object:nil];
    [nc addObserver:self selector:@selector(updateApplicationBadge:) name:MA_Notify_AppBadgeModeChanged object:nil];
    
    [mainWindow makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
    
    // Set status bar background color
    _statusBarHeight = statusBar.frame.size.height;
    statusBar.layer.backgroundColor = [NSColor colorWithCalibratedRed:0.21 green:0.91 blue:0.91 alpha:1.00].CGColor;
    
    // Show/hide the status bar based on the last session state
    Preferences * prefs = [Preferences standardPreferences];
    [self setStatusBarState:[prefs viewStatusBar] withAnimation:NO];
    
    [self initialiseMainWindow];
    [foldersTree initialiseFoldersTree];
    
    [self setSearchMenu];
    
    // Create a backtrack array
    _backtrackArray = [[BackTrackArray alloc] initWithMaximum:[prefs backTrackQueueSize]];
    
    // Handle URL scheme callbacks.
    NSAppleEventManager * appleEventManager = [NSAppleEventManager sharedAppleEventManager];
    [appleEventManager setEventHandler:self
                           andSelector:@selector(handleGetURLEvent:withReplyEvent:)
                         forEventClass:kInternetEventClass
                            andEventID:kAEGetURL];
    
    // Timer to update the status bar
    [NSTimer scheduledTimerWithTimeInterval:60.0
                                     target:self
                                   selector:@selector(updateLastSynchronisationText:)
                                   userInfo:nil
                                    repeats:YES];
    
    // Start the CIX synchroniser
    [CIX startTask];
    
    // Update app badge
    [self updateApplicationBadge:nil];
    
    // Navigate to the last address we were at. If none then default to showing
    // the Welcome view.
    if (_launchAddress != nil)
        [self setAddress:_launchAddress];
    else
    {
        NSString * lastAddress = [prefs lastAddress];
        if (!IsEmpty(lastAddress) && !prefs.startAtHomePage)
            [self setAddress:lastAddress];
        else
            [self selectView:AppViewWelcome withFolder:nil withAddress:nil options:0];
    }
    
    // Restore the split bar layout
    [splitter setViewRects:[prefs foldersViewLayout]];
    [splitter setDelegate:self];
}

/* Called when the application is about to shut down. Check whether
 * we can really terminate here.
 */
-(NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)app
{
    NSArray * windows = [[WindowCollection defaultCollection] collection];
    if (windows != nil)
    {
        for (NSWindowController<NSWindowDelegate> * ctrl in windows)
        {
            if (![ctrl windowShouldClose:self])
                return NSTerminateCancel;
            [ctrl close];
        }
    }
    return NSTerminateNow;
}

/* Called when the application is about to shut down. Save the last address
 * viewed and close out the log file.
 */
-(void)applicationWillTerminate:(NSNotification *)aNotification
{
    [CIX close];
    
    Preferences * prefs = [Preferences standardPreferences];
    if (_currentView != nil)
        [prefs setLastAddress:[_currentView address]];
    
    LogFile * logFile = LogFile.logFile;
    [logFile writeLine:@"%@ %@ shut down", [self applicationTitle], [self applicationVersion]];
    [logFile close];
}

/* Handle the command to sign out of CIXReader and restart the login.
 */
-(IBAction)handleSignOut:(id)sender
{
    Preferences * prefs = [Preferences standardPreferences];
    [prefs setLastUser:@""];
    [CIX deletePassword];
    
    NSString * daemonPath = [[NSBundle mainBundle] pathForResource:NSApplicationRelaunchDaemon ofType:nil];
    NSString * processIDString = [NSString stringWithFormat:@"%d", [[NSProcessInfo processInfo] processIdentifier]];
    [NSTask launchedTaskWithLaunchPath:daemonPath arguments:@[[[NSBundle mainBundle] bundlePath], processIDString]];
    
    [NSApp terminate:self];
}

/* This method is invoked when the user clicks on a URL scheme we handle (such as cix:) from
 * outside CIXReader.
 */
-(void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    NSString *urlAsString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    [self setAddress:urlAsString];
}

/* Initialise the log file.
 */
-(void)initialiseLogFile
{
    Preferences * prefs = [Preferences standardPreferences];
    
    LogFile * logFile = LogFile.logFile;
    
    [logFile setPath:[[CIX homeFolder] stringByAppendingPathComponent:@"cixreader.debug.log"]];
    [logFile setEnabled:[prefs enableLogFile]];
    [logFile setArchive:[prefs archiveLogFile]];
    [logFile setCumulative:[prefs cumulativeLogFile]];
}

/* Do the database initialisation.
 */
-(BOOL)initialiseDatabase
{
    Preferences * prefs = [Preferences standardPreferences];
    
    NSString * docFolder = CIX.homeFolder;
    NSString * username = [prefs lastUser];
    NSString * lastUsername = username;
    NSString * password = @"";
    NSString * databasePath;
    
    // First, tell APIRequest to use the beta API if we're enrolled
    // in the beta.
    [APIRequest setUseBetaAPI:[prefs useBeta]];
    
    if (!IsEmpty(username))
    {
        databasePath = [docFolder stringByAppendingPathComponent:username];
        databasePath = [databasePath stringByAppendingPathExtension:@"cixreader"];
        
        // If the last user database was externally removed, we need to
        // prompt for credentials again.
        if (![[NSFileManager defaultManager] doesFileExist:databasePath])
            username = @"";
    }
    
    LoginController * loginController = [[LoginController alloc] init];
    NSWindow * loginWindow = [loginController window];
    
    [loginWindow center];
    
    if (IsEmpty(username))
    {
        [prefs setLastUser:@""];
        
        BOOL accepted = [NSApp runModalForWindow: loginWindow];
        [NSApp endSheet: loginWindow];
        [loginWindow orderOut: self];
        
        if (!accepted)
            return NO;
        
        username = [loginController username];
        password = [loginController password];
    }
    
    databasePath = [docFolder stringByAppendingPathComponent:username];
    databasePath = [databasePath stringByAppendingPathExtension:@"cixreader"];
    
    if (![CIX init:databasePath])
    {
        NSAlert * alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:NSLocalizedString(@"Quit", nil)];
        [alert setMessageText:NSLocalizedString(@"Error", nil)];
        [alert setInformativeText:NSLocalizedString(@"Cannot open database", nil)];
        [alert setAlertStyle:NSAlertStyleWarning];

        return NO;
    }
    
    [CIX setUsername:username];
    
    // If a cached username was specified and it matches the username we have then we
    // use that to indicate that the password in the DB is to be used. Otherwise we need
    // the user to authenticate against the database password.
    if (IsEmpty(CIX.username) || IsEmpty(CIX.password))
    {
        if (IsEmpty(username) || IsEmpty(password))
        {
            [loginController setUsername:CIX.username];
            [loginController setPassword:CIX.password];
            
            BOOL accepted = [NSApp runModalForWindow: loginWindow];
            [NSApp endSheet: loginWindow];
            [loginWindow orderOut: self];
            
            if (!accepted)
                return NO;
            
            username = [loginController username];
            password = [loginController password];
        }
    }
    
    // If no cached username and password, then this is a new database
    // so persist the username there.
    if (IsEmpty(CIX.username) || IsEmpty(CIX.password))
    {
        [CIX setUsername:username];
        [CIX setPassword:password];
    }
    
    // If username changed, clear preferences that are related to the
    // username.
    if (![lastUsername isEqualToString:username])
        [prefs setLastAddress:@""];
    
    // Compact the database if the time is ripe
    if (prefs.cacheCleanUpFrequency > 0)
    {
        NSDateComponents * dayComponent = [[NSDateComponents alloc] init];
        dayComponent.day = prefs.cacheCleanUpFrequency;
        
        NSCalendar *theCalendar = [NSCalendar currentCalendar];
        NSDate * nextCacheCleanupTime = [theCalendar dateByAddingComponents:dayComponent toDate:prefs.lastCacheCleanUpDate options:0];
        if ([nextCacheCleanupTime isLessThanOrEqualTo:NSDate.date])
        {
            [CIX compactDatabase];
            [prefs setLastCacheCleanUpDate:NSDate.date];
        }
    }
    
    // Trigger an authentication to get the account type
    [CIX authenticate:CIX.username withPassword:CIX.password];
    return YES;
}

/* applicationDidResignActive
 * Do the things we need to do when CIXReader becomes inactive, like greying out.
 */
-(void)applicationDidResignActive:(NSNotification *)aNotification
{
    [foldersTree activate:NO];
}

/* applicationDidBecomeActive
 * Do the things we need to do when CIXReader becomes active, like re-coloring view backgrounds.
 */
-(void)applicationDidBecomeActive:(NSNotification *)notification
{
    [foldersTree activate:YES];
}

/* Called when the user opens a data file associated with CIXReader by clicking in the finder or dragging it onto the dock.
 */
-(BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
    if ([[filename pathExtension] isEqualToString:@"cixstyle"])
    {
        NSString * styleName = [[filename lastPathComponent] stringByDeletingPathExtension];
        NSString * stylesFolder = [CIX.homeFolder stringByAppendingPathComponent:@"Styles"];
        
        if (![self installFilename:filename toPath:stylesFolder])
            [[Preferences standardPreferences] setDisplayStyle:styleName];
        else
        {
            Preferences * prefs = [Preferences standardPreferences];
            [StyleController loadStylesMap];
            [prefs setDisplayStyle:styleName];
            if ([[prefs displayStyle] isEqualToString:styleName])
            {
                NSAlert * alert = [[NSAlert alloc] init];
                [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
                [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"The style \"%@\" has been installed to your Styles folder.", nil), styleName]];
                [alert setAlertStyle:NSAlertStyleWarning];
                [alert runModal];
            }
        }
        return YES;
    }
    return NO;
}

/* Copies the folder at srcFile to the specified path. The path is created if it doesn't already exist and
 * an error is reported if we fail to create the path. The return value is the result of copying the source
 * folder to the new path.
 */
-(BOOL)installFilename:(NSString *)srcFile toPath:(NSString *)path
{
    NSString * fullPath = [path stringByAppendingPathComponent:[srcFile lastPathComponent]];
    
    // Make sure we actually have a destination folder.
    NSFileManager * fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    
    if (![fileManager fileExistsAtPath:path isDirectory:&isDir])
    {
        if (![fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:NULL error:NULL])
        {
            NSAlert * alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
            [alert setMessageText:NSLocalizedString(@"Cannot create folder", nil)];
            [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"The \"%@\" folder cannot be created.", nil), path]];
            [alert setAlertStyle:NSAlertStyleWarning];
            [alert runModal];
            return NO;
        }
    }
    
    [fileManager removeItemAtPath:fullPath error:nil];
    return [fileManager copyItemAtPath:srcFile toPath:fullPath error:nil];
}

/* Close the app when the main window is closed.
 */
-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

/* Build the main window top-level layout.
 */
-(void)initialiseMainWindow
{
    NSToolbar * toolbar = [[NSToolbar alloc] initWithIdentifier:@"MA_Toolbar"];
    [toolbar setDelegate:self];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
    [mainWindow setToolbar:toolbar];
    
    // Make sure we get notifications
    [mainWindow setDelegate:self];
    
    // Set the initial online/offline state
    Preferences * prefs = [Preferences standardPreferences];
    [self setOnlineState:![prefs startOffline]];
    
    _allowOnlineStateChange = CIX.online;
}

/* Notification when network state changes
 */
-(void)reachabilityDidChange:(NSNotification *)notification
{
    if (_allowOnlineStateChange)
    {
        Reachability *reachability = (Reachability *)[notification object];
        [self setOnlineState:[reachability isReachable]];
        
        LogFile * logFile = LogFile.logFile;
        [logFile writeLine:@"Network state change detected: Online state is %@", BoolToString(CIX.online)];
    }
}

/* Programmatically change CIXReader's online state
 */
-(void)setOnlineState:(BOOL)newState
{
    [CIX setOnline:newState];
    [self updateCaption];
}

/* Parse and navigate to the address string using the internal scheme.
 */
-(void)setAddress:(NSString *)addressString
{
    if (addressString != nil)
    {
        Address * address = [[Address alloc] initWithString:addressString];
        if (address.scheme != nil)
            [self setAddressWithAddress:[self normaliseAddress:address]];
    }
}

/* Normalise the address by expanding truncated versions such as cix:1234 or cix:/topic:1234
 * to their full address version to make subsequent parsing easier.
 */
-(Address *)normaliseAddress:(Address *)address
{
    if (address.scheme != nil)
    {
        if (IsEmpty(address.query))
        {
            NSString * oldData = address.data;
            address = [[Address alloc] initWithString:foldersTree.selection.address];
            address.data = oldData;
        }

        // Special case the cix:/topic convention here because it requires us to
        // know the forum from the selection which is only possible when we have
        // the UI from which to determine the selection.
        else if ([address.query hasPrefix:@"/"])
        {
            FolderBase * folder = foldersTree.selection;
            if ([folder isKindOfClass:TopicFolder.class] && !IsTopLevelFolder(((TopicFolder *)folder).folder))
            {
                Folder * forum = ((TopicFolder *)folder).folder.parentFolder;
                address.query = [NSString stringWithFormat:@"%@%@", forum.name, address.query];
            }
        }
    }
    return address;
}

/* Return the message that corresponds to a given CIX address if possible, or nil if
 * the input does not reference a valid message.
 */
-(Message *)messageFromAddress:(NSString *)string
{
    Address * address = [[Address alloc] initWithString:string];
    if (address != nil && address.scheme != nil && [address.data intValue] > 0)
    {
        address = [self normaliseAddress:address];
    
        NSArray * splitAddress = [address.query componentsSeparatedByString:@"/"];
        if (splitAddress != nil && splitAddress.count == 2)
        {
            Folder * forum = [CIX.folderCollection folderByName:splitAddress[0]];
            Folder * topic = [forum childByName:splitAddress[1]];
            return [[topic messages] messageByID:[address.data intValue]];
        }
    }
    return nil;
}

/* Navigate to the specified address using the internal scheme.
 */
-(void)setAddressWithAddress:(Address *)address
{
    if (address != nil)
    {
        // Handle cixuser: by showing the user's profile
        if ([address.scheme isEqualToString:@"cixuser"])
        {
            Profile * profile = [Profile profileForUser:address.query];
            if (profile != nil)
            {
                ProfileController * profileController = [[ProfileController alloc] initWithProfile:profile];
                [NSApp activateIgnoringOtherApps:YES];
                [profileController showWindow:self];
            }
            return;
        }
        
        // Handle cixmail: by bringing up an empty pmessage window
        if ([address.scheme isEqualToString:@"cixmail"])
        {
            MailEditor * msgWindow = [[MailEditor alloc] initWithRecipient:address.data];
            [msgWindow showWindow:self];
            [[msgWindow window] makeKeyAndOrderFront:self];
            return;
        }
        
        // Test each view in turn to see if they can handle the scheme and
        // pass the address through if so.
        for (NSNumber * appView in [_allViews allKeys])
        {
            ViewBaseView * view = _allViews[appView];
            if ([view handles:address.scheme])
            {
                if ([foldersTree selectAddress:address])
                    return;
                
                // If we get here, the URL is to a forum or topic that isn't
                // local, so we need to join it.
                if ([self joinMissingForum:address])
                    return;
                
                break;
            }
        }
        
        // If we get here, the URL is invalid so default to the Welcome screen.
        [self selectView:AppViewWelcome withFolder:nil withAddress:nil options:0];
    }
}

/* Handle the case where address points to a forum or topic that is absent
 * from the local database.
 */
-(BOOL)joinMissingForum:(Address *)address
{
    NSArray * splitAddress = [address.query componentsSeparatedByString:@"/"];
    
    if (splitAddress == nil || splitAddress.count == 0)
        return NO;
    
    JoinForumController * joinForumController = [[JoinForumController alloc] initWithName:splitAddress[0]];
    NSWindow * joinForumWindow = [joinForumController window];
    
    [joinForumWindow center];
    
    [NSApp runModalForWindow:joinForumWindow];
    [NSApp endSheet:joinForumWindow];
    [joinForumWindow orderOut: self];
    
    return YES;
}

/* Handle notifications that require the application icon and badge to be refreshed.
 */
-(void)updateApplicationBadge:(NSNotification *)notification
{
    Preferences * prefs = [Preferences standardPreferences];
    
    if (prefs.appBadgeMode == AppBadgeNone)
        [[NSApp dockTile] setBadgeLabel:nil];
    else
    {
        NSInteger count = (prefs.appBadgeMode == AppBadgeUnreadPriorityCount) ? CIX.totalUnreadPriority : CIX.totalUnread;
        [[NSApp dockTile] setBadgeLabel:(count > 0) ? [NSString stringWithFormat:@"%li", (long)count] : nil];
    }
}

/* Update the application title bar.
 */
-(void)updateCaption
{
    NSMutableString * captionBar = [[NSMutableString alloc] initWithString:[self applicationTitle]];
    if (self.userTitleString != nil)
        [captionBar appendFormat:@" - %@", self.userTitleString];
    
    if (!CIX.online)
        [captionBar appendFormat:@" - %@", NSLocalizedString(@"Offline", nil)];
    
    [mainWindow setTitle:captionBar];
}

/* Return the current user-defined title string that appears
 * in the caption bar.
 */
-(NSString *)userTitleString
{
    return _userTitleString;
}

/* Change the user-defined title string and update the caption bar.
 */
-(void)setUserTitleString:(NSString *)newUserTitleString
{
    _userTitleString = newUserTitleString;
    [self updateCaption];
}

/* Respond to the synchronisation started event.
 */
-(void)handleSynchronisationStarted:(NSNotification *)notification
{
    [self setStatusMessage:NSLocalizedString(@"Synchronisation started...", nil) persist:YES];
    [self startProgressIndicator];
}

/* Respond to the synchronisation completion event.
 */
-(void)handleSynchronisationCompleted:(NSNotification *)notification
{
    _lastSyncTime = [NSDate date];
    [self updateLastSynchronisationText:nil];
    [self stopProgressIndicator];
}

/* Show the last sychronisation time in a user-friendly format. Since this is called
 * on a timer each minute, the granularity of the message is to the minute.
 */
-(void)updateLastSynchronisationText:(NSTimer *)timer
{
    if (_lastSyncTime != nil)
    {
        NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:_lastSyncTime];
        NSString * elapsedText;
        
        if (elapsed >= 60*60)
        {
            int hours = elapsed / 60*60;
            elapsedText = (hours == 1) ? NSLocalizedString(@"one hour ago", nil) : [NSString stringWithFormat:NSLocalizedString(@"%d hours ago", nil), hours];
        }
        else if (elapsed >= 60)
        {
            int minutes = elapsed / 60;
            elapsedText = (minutes == 1) ? NSLocalizedString(@"one minute ago", nil) : [NSString stringWithFormat:NSLocalizedString(@"%d minutes ago", nil), minutes];
        }
        else
            elapsedText = @"";
        NSString * text = [NSString stringWithFormat:NSLocalizedString(@"Synchronisation completed %@", nil), elapsedText];
        [self setStatusMessage:text persist:YES];
    }
}

/* Save the splitter position
 */
-(void)splitViewDidResizeSubviews:(NSNotification *)notification
{
    [[Preferences standardPreferences] setFoldersViewLayout:[splitter viewRects]];
}

/* Intercept for the delete: action on the NSApp target.
 */
-(IBAction)handleFolderDelete:(id)sender
{
    FolderBase * folder = [foldersTree selection];
    [folder delete];
}

/* Intercept for the resign action.
 */
-(IBAction)handleFolderResign:(id)sender
{
    FolderBase * folder = [foldersTree selection];
    if (folder != nil && [folder isKindOfClass:TopicFolder.class])
        [(TopicFolder *)folder resign];
}

/* Intercept for the mark all read action.
 */
-(IBAction)handleMarkAllRead:(id)sender
{
    FolderBase * folder = [foldersTree selection];
    [folder markAllRead];
}

/* Mark the current thread read.
 */
-(IBAction)handleMarkReadThread:(id)sender
{
    [_currentView action:ActionIDMarkThreadRead];
    if (CIX.totalUnread > 0)
        [foldersTree nextUnread:FolderOptionsNextUnread];
}

/* Mark the current thread read then go to the root of the
 * next thread with unread messages.
 */
-(IBAction)handleMarkReadThreadThenRoot:(id)sender
{
    [_currentView action:ActionIDMarkThreadRead];
    if (CIX.totalUnread > 0)
        [foldersTree nextUnread:FolderOptionsNextUnread|FolderOptionsRoot];
}

/* Expand or collapse the current root thread. Do nothing if we're
 * not on a root message.
 */
-(IBAction)handleExpandCollapseThread:(id)sender
{
    [_currentView action:ActionIDExpandCollapseThread];
}

/* Only show recent topics in the folders tree.
 */
-(IBAction)handleRecentTopics:(id)sender
{
    Preferences * prefs = [Preferences standardPreferences];
    [prefs setShowAllTopics:NO];
}

/* Show all topics in the folders tree.
 */
-(IBAction)handleAllTopics:(id)sender
{
    Preferences * prefs = [Preferences standardPreferences];
    [prefs setShowAllTopics:YES];
}

/* Join a forum
 * Give the current view an opportunity to handle the Join action especially, otherwise
 * put up the stock Join Forum window.
 */
-(IBAction)handleJoinForum:(id)sender
{
    if ([_currentView canAction:ActionIDJoin])
        [_currentView action:ActionIDJoin];
    else
    {
        if (_joinForumInputController == nil)
            _joinForumInputController = [JoinForumInput new];
        [mainWindow beginSheet:_joinForumInputController.window completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == NSModalResponseOK)
            {
                [_joinForumInputController.window orderOut:self];
                
                JoinForumController * joinForumController = [[JoinForumController alloc] initWithName:_joinForumInputController.name];
                NSWindow * joinForumWindow = [joinForumController window];
                
                [joinForumWindow center];
                
                [NSApp runModalForWindow:joinForumWindow];
                [NSApp endSheet:joinForumWindow];
                [joinForumWindow orderOut: self];
            }
        }];
    }
}

/* Create and send a new pmessage.
 */
-(IBAction)handleNewMail:(id)sender
{
    [self setAddress:@"cixmail:new"];
}

/* Reply to the selected message via a pmessage.
 */
-(IBAction)handleReplyByMail:(id)sender
{
    if ([_currentView canAction:ActionIDReplyByMail])
        [_currentView action:ActionIDReplyByMail];
}

/* Create a reply to the selected message
 */
-(IBAction)handleReply:(id)sender
{
    if ([_currentView canAction:ActionIDReply])
        [_currentView action:ActionIDReply];
}

/* Handle the quote command
 */
-(IBAction)quoteOriginal:(id)sender
{
    if ([_currentView canAction:ActionIDReplyWithQuote])
        [_currentView action:ActionIDReplyWithQuote];
}

/* Display the profile for the user selected in the
 * current view.
 */
-(IBAction)handleShowProfile:(id)sender
{
    [_currentView action:ActionIDShowProfile];
}

/* Create a new CIX message in the current topic.
 */
-(IBAction)handleNewMessage:(id)sender
{
    if ([_currentView canAction:ActionIDNewMessage])
        [_currentView action:ActionIDNewMessage];
}

/* Edit the selected message
 */
-(IBAction)handleEditMessage:(id)sender
{
    if ([_currentView canAction:ActionIDEditMessage])
        [_currentView action:ActionIDEditMessage];
}

/* Reply to the selected CIX message in the current topic.
 */
-(IBAction)handleComment:(id)sender
{
    if ([_currentView canAction:ActionIDReply])
        [_currentView action:ActionIDReply];
}

/* Handle the Print command in the current context.
 */
-(IBAction)printDocument:(id)sender
{
    [_currentView action:ActionIDPrint];
}

/* Go to a message
 */
-(IBAction)handleGoTo:(id)sender
{
    if ([_currentView canAction:ActionIDGoto])
        [_currentView action:ActionIDGoto];
}

/* Go to the message parent
 */
-(IBAction)handleGoToOriginal:(id)sender
{
    if ([_currentView canAction:ActionIDGotoOriginal])
        [_currentView action:ActionIDGotoOriginal];
}

/* Go to the current message root
 */
-(IBAction)handleGoToPreviousRoot:(id)sender
{
    [_currentView action:ActionIDGotoPreviousRoot];
}

/* Go to the next message root
 */
-(IBAction)handleGoToNextRoot:(id)sender
{
    [_currentView action:ActionIDGotoNextRoot];
}

/* Toggle read/unread on the current message
 */
-(IBAction)handleMarkRead:(id)sender
{
    if ([_currentView canAction:ActionIDMarkRead])
        [_currentView action:ActionIDMarkRead];
}

/* Toggle readlock on the current message
 */
-(IBAction)handleMarkReadLock:(id)sender
{
    if ([_currentView canAction:ActionIDMarkReadLock])
        [_currentView action:ActionIDMarkReadLock];
}

/* Toggle star on the current message
 */
-(IBAction)handleMarkStar:(id)sender
{
    if ([_currentView canAction:ActionIDMarkStar])
        [_currentView action:ActionIDMarkStar];
}

/* Toggle priority on the current message
 */
-(IBAction)handleMarkPriority:(id)sender
{
    if ([_currentView canAction:ActionIDMarkPriority])
        [_currentView action:ActionIDMarkPriority];
}

/* Toggle ignore on the current message
 */
-(IBAction)handleMarkIgnore:(id)sender
{
    if ([_currentView canAction:ActionIDMarkIgnore])
        [_currentView action:ActionIDMarkIgnore];
}

/* Withdraw the selected message
 */
-(IBAction)handleWithdraw:(id)sender
{
    if ([_currentView canAction:ActionIDWithdraw])
        [_currentView action:ActionIDWithdraw];
}

/* Block the author of the selected message
 */
-(IBAction)handleBlock:(id)sender
{
    if ([_currentView canAction:ActionIDBlock])
        [_currentView action:ActionIDBlock];
}

/* Go to the next unread message.
 */
-(IBAction)handleNextUnread:(id)sender
{
    if (CIX.totalUnread > 0)
        [foldersTree nextUnread:FolderOptionsNextUnread];
}

/* Go to the next unread priority message.
 */
-(IBAction)handleNextUnreadPriority:(id)sender
{
    if (CIX.totalUnreadPriority > 0)
        [foldersTree nextUnread:FolderOptionsNextUnread|FolderOptionsPriority];
}

/* Scroll the current message if possible, otherwise go to the
 * next unread message.
 */
-(IBAction)handleScrollThenNextUnread:(id)sender
{
    if ([_currentView canAction:ActionIDScrollMessage])
        return [_currentView action:ActionIDScrollMessage];
    
    [self handleNextUnread:self];
}

/* Handle the command to increase the display text size.
 */
-(IBAction)handleBiggerText:(id)sender
{
    [_currentView action:ActionIDBiggerText];
}

/* Handle the command to reduce the display text size
 */
-(IBAction)handleSmallerText:(id)sender
{
    [_currentView action:ActionIDSmallerText];
}

/* Handle the command to copy a link to the current message to
 * the clipboard.
 */
-(IBAction)handleCopyLink:(id)sender
{
    NSString * link = [_currentView address];
    if (link != nil)
    {
        NSPasteboard * pb = [NSPasteboard generalPasteboard];
        
        [pb declareTypes:@[NSStringPboardType] owner:nil];
        [pb setString:link forType:NSStringPboardType];
    }
}

/* Handle the command to invoke Moderator management of the
 * selected forum.
 */
-(IBAction)handleForumManage:(id)sender
{
    [_currentView action:ActionIDManage];
}

/* Handle the command to display the forum participants.
 */
-(IBAction)handleForumParticipants:(id)sender
{
    [_currentView action:ActionIDParticipants];
}

/* Handle the Delete command in the Edit menu. This is context sensitive so
 * we need to pass it through to the active view.
 */
-(IBAction)delete:(id)sender
{
    [_currentView action:ActionIDDelete];
}

/* Activate the view for the specified folder.
 */
-(BOOL)selectViewForFolder:(FolderBase *)folder withAddress:(Address *)address options:(FolderOptions)options
{
    int requestedView = [folder viewForFolder];
    return [self selectView:requestedView withFolder:folder withAddress:address options:options];
}

/* Activate the specified view with the given folder. The folder
 * can be nil here in which case the view displays the default view.
 */
-(BOOL)selectView:(AppView)requestedView withFolder:(FolderBase *)folder withAddress:(Address *)address options:(FolderOptions)options
{
    if (_currentAppView != requestedView)
    {
        ViewBaseView * newViewController = _allViews[@(requestedView)];
        if (newViewController == nil)
            return NO;
        
        NSView * newView = [newViewController view];
        if (_currentView != nil)
        {
            [[_currentView view] removeFromSuperview];
            _currentView = nil;
        }
        
        [newView setFrame:[contentView bounds]];
        [newView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [contentView addSubview:newView];
        
        NSDictionary *views = NSDictionaryOfVariableBindings(newView);
        [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[newView]|"
                                                                            options:0
                                                                            metrics:nil
                                                                              views:views]];
        
        [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[newView]|"
                                                                            options:0
                                                                            metrics:nil
                                                                              views:views]];
        [contentView.window layoutIfNeeded];
        
        // Update the menu bar for the new view
        NSMenu * sortMenuItems = [newViewController sortMenu];
        if (sortMenuItems == nil)
            [sortMenu setEnabled:NO];
        else
        {
            [sortMenu setEnabled:YES];
            [[NSApp menu] setSubmenu:sortMenuItems forItem:sortMenu];
        }
        _currentView = newViewController;
        _currentAppView = requestedView;
    }
    
    // Always clear the search view when we switch
    [searchFieldOutlet setStringValue:@""];
    
    NSString * placeholder;
    if (folder.allowsScopedSearch)
        placeholder = [NSString stringWithFormat:NSLocalizedString(@"Search in %@", nil), folder.name];
    else
        placeholder = NSLocalizedString(@"Search", nil);
    [[searchFieldOutlet cell] setPlaceholderString:placeholder];
    
    // Set the window title
    [self setUserTitleString:folder.fullName];
    [self updateCaption];
    
    return [_currentView viewFromFolder:folder withAddress:address options:options];
}

/* Return the application version number from the application's
 * own info.plist.
 */
-(NSString *)applicationVersion
{
    NSDictionary * infoDictionary = [[NSBundle mainBundle] infoDictionary];
    return infoDictionary[@"CFBundleShortVersionString"];
}

/* Return the application's name from its own info.plist.
 */
-(NSString *)applicationTitle
{
    NSDictionary * infoDictionary = [[NSBundle mainBundle] infoDictionary];
    return infoDictionary[@"CFBundleName"];
}

/* Return a cached instance of NSLayoutManager for calculating the font height.
 */
-(NSLayoutManager *)layoutManager
{
    static NSLayoutManager * theManager = nil;
    
    if (theManager == nil)
        theManager = [[NSLayoutManager alloc] init];
    return theManager;
}

/* Return the current selected topic folder.
 */
-(Folder *)currentFolder
{
    FolderBase * folderBase = [foldersTree selection];
    if (folderBase != nil && [folderBase isKindOfClass:TopicFolder.class])
        return ((TopicFolder *)folderBase).folder;
    return nil;
}

/* Return the current selected Message
 */
-(Message *)currentMessage
{
    return nil;
}

/* Displays the Acknowledgements.html file in the user's browser.
 */
-(IBAction)showAcknowledgements:(id)sender
{
    NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
    NSString * pathToFile = [thisBundle pathForResource:@"Acknowledgements" ofType:@"html"];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:pathToFile]];
}

/* Display the CIXReader Preferences panel.
 */
-(IBAction)showPreferencesPanel:(id)sender
{
    if (!_preferenceController)
        _preferenceController = [[MultiViewController alloc] initWithConfig:@"Preferences.plist" andData:nil];
    
    [NSApp activateIgnoringOtherApps:YES];
    [_preferenceController showWindow:self];
}

/* Display the Accounts panel.
 */
-(IBAction)showAccountPanel:(id)sender
{
    AccountController * accountController = [[AccountController alloc] init];
    
    NSWindow * accountWindow = [accountController window];
    
    [accountWindow center];
    
    [NSApp runModalForWindow:accountWindow];
    [NSApp endSheet:accountWindow];
    [accountWindow orderOut: self];
}

/* Toggle online/offline state
 */
-(IBAction)toggleOffline:(id)sender
{
    [self setOnlineState:!CIX.online];
    _allowOnlineStateChange = CIX.online;
    
    LogFile * logFile = LogFile.logFile;
    [logFile writeLine:@"User changed online state to %@", BoolToString(CIX.online)];
}

/* Open the browser at the CIX support page.
 */
-(IBAction)showHelpSupport:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.cix.uk/support"]];
}

/* Do the check for updates.
 */
-(IBAction)handleCheckForUpdates:(id)sender
{
    [[SUUpdater sharedUpdater] checkForUpdates:self];
}

/* Gets the progress indicator on the info bar running. Because this can be called
 * nested, we use progressCount to make sure we remove it at the right time.
 */
-(void)startProgressIndicator
{
    if (_progressCount++ == 0)
        [spinner startAnimation:self];
}

/* Stops the progress indicator on the info bar running
 */
-(void)stopProgressIndicator
{
    NSAssert(_progressCount > 0, @"Called stopProgressIndicator without a matching startProgressIndicator");
    if (--_progressCount < 1)
    {
        [spinner stopAnimation:self];
        _progressCount = 0;
    }
}

/* isStatusBarVisible
 * Simple function that returns whether or not the status bar is visible.
 */
-(BOOL)isStatusBarVisible
{
    return [Preferences.standardPreferences viewStatusBar];
}

/* handleShowStatusBar
 * Respond to the status bar state being changed programmatically.
 */
-(void)handleShowStatusBar:(NSNotification *)notification
{
    [self setStatusBarState:[self isStatusBarVisible] withAnimation:YES];
}

/* Toggle the setting for showing plaintext vs. mark-up
 */
-(IBAction)handleShowPlaintext:(id)sender
{
    Preferences * prefs = [Preferences standardPreferences];
    [prefs setIgnoreMarkup:![prefs ignoreMarkup]];
}

/* Toggle the setting for showing inline images
 */
-(IBAction)handleShowInlineImages:(id)sender
{
    Preferences * prefs = [Preferences standardPreferences];
    [prefs setDownloadInlineImages:![prefs downloadInlineImages]];
}

/* Toggle the setting for showing ignored messages
 */
-(IBAction)handleShowIgnored:(id)sender
{
    Preferences * prefs = [Preferences standardPreferences];
    [prefs setShowIgnored:![prefs showIgnored]];
}

/* Toggle the setting for changing conversation grouping
 */
-(IBAction)handleGroupByConv:(id)sender
{
    Preferences * prefs = [Preferences standardPreferences];
    [prefs setGroupByConv:![prefs groupByConv]];
}

/* Toggle the setting for collapsing conversations
 */
-(IBAction)handleCollapseConv:(id)sender
{
    Preferences * prefs = [Preferences standardPreferences];
    [prefs setCollapseConv:![prefs collapseConv]];
}

/* Refresh the selected folder.
 */
-(IBAction)handleRefresh:(id)sender
{
    FolderBase * selection = [foldersTree selection];
    if (selection != nil)
        [selection refresh];
}

/* Display the change log.
 */
-(IBAction)handleViewChangeLog:(id)sender
{
    Preferences * prefs = [Preferences standardPreferences];
    NSString * betaOrRelease = [prefs useBeta] ? @"beta" : @"release";
    
    NSString * url = [NSString stringWithFormat:@"https://cixreader.cixhosting.co.uk/cixreader/osx/%@/changes.html", betaOrRelease];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
}

/* The default handler for the Find actions is the first responder.
 */
-(IBAction)performFindPanelAction:(id)sender
{
    switch ([sender tag])
    {
        case NSFindPanelActionSetFindString:
        case NSFindPanelActionShowFindPanel:
            [self setFocusToSearchField:self];
            break;
            
            default:
            NSAssert(false, @"Unhandled performFindPanelAction tag value");
            break;
    }
}

/* Put the input focus on the search field.
 */
-(IBAction)setFocusToSearchField:(id)sender
{
    if ([[mainWindow toolbar] isVisible] &&
        [self toolbarItemWithIdentifier:@"SearchBar"] &&
        [[mainWindow toolbar] displayMode] != NSToolbarDisplayModeLabelOnly)
        [mainWindow makeFirstResponder:searchFieldOutlet];
}

/* Handle the response from the Search Panel on the toolbar.
 */
-(IBAction)searchUsingSearchPanel:(id)sender
{
    NSString * searchString = [searchFieldOutlet stringValue];
    FolderBase * folder = [foldersTree selection];
    
    if ([searchString isBlank])
    {
        [self selectViewForFolder:folder withAddress:nil options:FolderOptionsClearFilter];
        return;
    }
    if (!folder.allowsScopedSearch)
    {
        SearchFolder * searchFolder = [foldersTree searchFolder];
        searchFolder.searchString = searchString;
        [foldersTree selectSearchFolder];
        return;
    }
    [_currentView filterViewByString:searchString];
}

/* Create the search menu
 */
-(void)setSearchMenu
{
    NSMenu *cellMenu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Search Menu", nil)];
    NSMenuItem *item;
    
    item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Clear", nil) action:NULL keyEquivalent:@""];
    [item setTag:NSSearchFieldClearRecentsMenuItemTag];
    [cellMenu insertItem:item atIndex:0];
    
    item = [NSMenuItem separatorItem];
    [item setTag:NSSearchFieldRecentsTitleMenuItemTag];
    [cellMenu insertItem:item atIndex:1];
    
    item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Recent Searches", nil) action:NULL keyEquivalent:@""];
    [item setTag:NSSearchFieldRecentsTitleMenuItemTag];
    [cellMenu insertItem:item atIndex:2];
    
    item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Recents", nil) action:NULL keyEquivalent:@""];
    [item setTag:NSSearchFieldRecentsMenuItemTag];
    [cellMenu insertItem:item atIndex:3];
    
    id searchCell = [searchFieldOutlet cell];
    [searchCell setSearchMenuTemplate:cellMenu];
}

/* showHideStatusBar
 * Toggle the status bar on/off. When off, expand the article area to fill the space.
 */
-(IBAction)showHideStatusBar:(id)sender
{
    BOOL newState = ![self isStatusBarVisible];
    
    [self setStatusBarState:newState withAnimation:YES];
    [[Preferences standardPreferences] setViewStatusBar:newState];
}

/* setStatusBarState
 * Show or hide the status bar state. Does not persist the state - use showHideStatusBar for this.
 */
-(void)setStatusBarState:(BOOL)isVisible withAnimation:(BOOL)doAnimate
{
    if (_isStatusBarVisible != isVisible)
    {
        if (!doAnimate)
            topConstraint.constant = (isVisible) ? _statusBarHeight : 0;
        else
        {
            [NSAnimationContext beginGrouping];
            [[NSAnimationContext currentContext] setDuration:0.05];
            topConstraint.animator.constant = (isVisible) ? _statusBarHeight : 0;
            [NSAnimationContext endGrouping];
        }
        _isStatusBarVisible = isVisible;
    }
}

/* Sets a new status message for the status bar then updates the view. To remove
 * any existing status message, pass nil as the value.
 */
-(void)setStatusMessage:(NSString *)newStatusText persist:(BOOL)persistenceFlag
{
    if (persistenceFlag)
        _persistedStatusText = newStatusText;
    
    if (IsEmpty(newStatusText))
        newStatusText = _persistedStatusText;
    
    [statusText setStringValue:(newStatusText ? newStatusText : @"")];
}


/* Returns the toolbar button that corresponds to the specified identifier.
 */
-(NSToolbarItem *)toolbarItemWithIdentifier:(NSString *)theIdentifier
{
    for (NSToolbarItem * theItem in [[mainWindow toolbar] visibleItems])
    {
        if ([[theItem itemIdentifier] isEqualToString:theIdentifier])
            return theItem;
    }
    return nil;
}

/* Add the specified article to the backtrack queue. The folder is taken from
 * the controller's current folder index.
 */
-(void)addBacktrack:(NSString *)address withUnread:(BOOL)unread
{
    if (!_isBacktracking && address != nil)
    {
        Address * item = [[Address alloc] initWithString:address];
        item.unread = unread;
        [_backtrackArray addToQueue:item];
    }
}

/* Move forward through the backtrack queue.
 */
-(IBAction)goForward:(id)sender
{
    Address * address;
    
    if ([_backtrackArray nextItemAtQueue:&address])
    {
        _isBacktracking = YES;
        [self setAddressWithAddress:[self normaliseAddress:address]];
        _isBacktracking = NO;
    }
}

/* Move backward through the backtrack queue.
 */
-(IBAction)goBack:(id)sender
{
    Address * address;
    
    if ([_backtrackArray previousItemAtQueue:&address])
    {
        _isBacktracking = YES;
        [self setAddressWithAddress:[self normaliseAddress:address]];
        _isBacktracking = NO;
    }
}

/* Return TRUE if we can go forward in the backtrack queue.
 */
-(BOOL)canGoForward
{
    return ![_backtrackArray isAtEndOfQueue];
}

/* Return TRUE if we can go backward in the backtrack queue.
 */
-(BOOL)canGoBack
{
    return ![_backtrackArray isAtStartOfQueue];
}

/* Support special key codes. If we handle the key, return YES otherwise
 * return NO to allow the framework to pass it on for default processing.
 */
-(BOOL)handleKeyDown:(unichar)keyChar withFlags:(NSUInteger)flags
{
    switch (keyChar)
    {
        case NSRightArrowFunctionKey:
            [self handleNextUnread:self];
            return YES;
            
        case NSLeftArrowFunctionKey:
            [self goBack:self];
            return YES;
            
        case ' ':
            [self handleScrollThenNextUnread:self];
            return YES;
            
        case ',':
            [self handleGoToPreviousRoot:self];
            return YES;
            
        case '.':
            [self handleGoToNextRoot:self];
            return YES;
            
        case '8':
            [self handleMarkStar:self];
            return YES;
            
        case 'b':
        case 'B':
            [self handleBlock:self];
            return YES;
            
        case 'c':
        case 'C':
            [self handleComment:self];
            return YES;
            
        case 'g':
        case 'G':
            [self handleGoTo:self];
            return YES;
            
        case 'h':
        case 'H':
            [self handleMarkPriority:self];
            return YES;
            
        case 'i':
        case 'I':
            [self handleMarkIgnore:self];
            return YES;
            
        case 'l':
        case 'L':
            [self handleMarkReadLock:self];
            return YES;
            
        case 'p':
        case 'P':
            [self handleNextUnreadPriority:self];
            return YES;
            
        case 'q':
        case 'Q':
            if ([_currentView canAction:ActionIDReplyWithQuote])
                [_currentView action:ActionIDReplyWithQuote];
            return YES;
            
        case 'r':
        case 'R':
            [self handleMarkRead:self];
            return YES;
            
        case 'o':
        case 'O':
            [self handleGoToOriginal:self];
            return YES;
            
        case 's':
        case 'S':
            [self handleNewMessage:self];
            return YES;
            
        case 'v':
        case 'V':
            [self handleShowPlaintext:self];
            return YES;
            
        case NSDeleteCharacter:
        case 'w':
        case 'W':
            [self handleWithdraw:self];
            return YES;
            
        case 'x':
        case 'X':
            [self handleExpandCollapseThread:self];
            return YES;
            
        case 'z':
            [self handleMarkReadThread:self];
            return YES;
            
        case 'Z':
            [self handleMarkReadThreadThenRoot:self];
            return YES;
            
            default:
            break;
    }
    return NO;
}

/* Check [theItem identifier] and return YES if the item is enabled, NO otherwise.
 */
-(BOOL)validateToolbarItem:(CRToolbarItem *)toolbarItem
{
    SEL theAction = [toolbarItem action];
    BOOL mainIsKey = [mainWindow isKeyWindow];
    BOOL flag = NO;
    
    if (![NSApp isActive])
        return NO;
    if (theAction == @selector(handleMarkRead:))
    {
        return (mainIsKey && _currentView != nil) ? [_currentView canAction:ActionIDMarkRead] : NO;
    }
    if (theAction == @selector(handleMarkStar:))
    {
        BOOL enabled = (mainIsKey && _currentView != nil) ? [_currentView canAction:ActionIDMarkStar] : NO;
        if (enabled)
            [toolbarItem compositeButtonImage:[_currentView imageForAction:ActionIDMarkStar]];
        return enabled;
    }
    if (theAction == @selector(handleMarkReadLock:))
    {
        BOOL enabled = (mainIsKey && _currentView != nil) ? [_currentView canAction:ActionIDMarkReadLock] : NO;
        if (enabled)
            [toolbarItem compositeButtonImage:[_currentView imageForAction:ActionIDMarkReadLock]];
        return enabled;
    }
    if (theAction == @selector(handleWithdraw:))
    {
        return (mainIsKey && _currentView != nil) ? [_currentView canAction:ActionIDWithdraw] : NO;
    }
    if (theAction == @selector(toggleOffline:))
    {
        [toolbarItem setLabel:CIX.online ? NSLocalizedString(@"Offline", nil) : NSLocalizedString(@"Online", nil)];
        return YES;
    }
    [self validateCommonToolbarAndMenuItems:[toolbarItem action] validateFlag:&flag];
    return flag;
}

/* Validation code for items that appear on both the toolbar and the menu. Since these are
 * handled identically, we validate here to avoid duplication of code in two delegates.
 * The return value is YES if we handled the validation here and no further validation is
 * needed, NO otherwise.
 */
-(BOOL)validateCommonToolbarAndMenuItems:(SEL)theAction validateFlag:(BOOL *)validateFlag
{
    BOOL mainIsKey = [mainWindow isKeyWindow];
    if (theAction == @selector(handleNextUnread:))
    {
        *validateFlag = CIX.totalUnread > 0;
        return YES;
    }
    if (theAction == @selector(handleNextUnreadPriority:))
    {
        *validateFlag = CIX.totalUnreadPriority > 0;
        return YES;
    }
    if (theAction == @selector(goBack:))
    {
        *validateFlag = [self canGoBack];
        return YES;
    }
    if (theAction == @selector(handleJoinForum:))
    {
        *validateFlag = YES;
        return YES;
    }
    if (theAction == @selector(printDocument:))
    {
        *validateFlag = (_currentView != nil) ? [_currentView canAction:ActionIDPrint] : NO;
        return YES;
    }
    if (theAction == @selector(handleComment:))
    {
        *validateFlag = (mainIsKey && _currentView != nil) ? [_currentView canAction:ActionIDReply] : NO;
        return YES;
    }
    if (theAction == @selector(handleNewMessage:))
    {
        *validateFlag = (_currentView != nil) ? [_currentView canAction:ActionIDNewMessage] : NO;
        return YES;
    }
    if (theAction == @selector(handleReply:))
    {
        *validateFlag = (mainIsKey && _currentView != nil) ? [_currentView canAction:ActionIDReply] : NO;
        return YES;
    }
    if (theAction == @selector(handleNewMail:))
    {
        *validateFlag = _currentView != nil;
        return YES;
    }
    if (theAction == @selector(searchUsingSearchPanel:))
    {
        *validateFlag = YES;
        return YES;
    }
    if (theAction == @selector(quoteOriginal:))
    {
        *validateFlag = (mainIsKey && _currentView != nil) ? [_currentView canAction:ActionIDReplyWithQuote] : NO;
        return YES;
    }
    if (theAction == @selector(handleShowProfile:))
    {
        *validateFlag = (mainIsKey && _currentView != nil) ? [_currentView canAction:ActionIDShowProfile] : NO;
        return YES;
    }
    return NO;
}

/* Do the menu initialisation when the user pulls down a menu item.
 */
-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    Preferences * prefs = [Preferences standardPreferences];
    SEL theAction = [menuItem action];
    BOOL mainIsKey = [mainWindow isKeyWindow];
    BOOL flag = NO;
    
    if ([self validateCommonToolbarAndMenuItems:theAction validateFlag:&flag])
    {
        return flag;
    }
    if (_currentView != nil)
    {
        if (mainIsKey && [_currentView validateMenuItem:menuItem])
            return YES;
    }
    if (theAction == @selector(toggleOffline:))
    {
        [menuItem setState:!CIX.online ? NSOnState : NSOffState];
        return YES;
    }
    if (theAction == @selector(handleAllTopics:))
    {
        [menuItem setState:[prefs showAllTopics] ? NSOnState : NSOffState];
        return YES;
    }
    if (theAction == @selector(handleRecentTopics:))
    {
        [menuItem setState:![prefs showAllTopics] ? NSOnState : NSOffState];
        return YES;
    }
    if (theAction == @selector(showHideStatusBar:))
    {
        if ([self isStatusBarVisible])
            [menuItem setTitle:NSLocalizedString(@"Hide Status Bar", nil)];
        else
            [menuItem setTitle:NSLocalizedString(@"Show Status Bar", nil)];
        return YES;
    }
    if (theAction == @selector(handleGoTo:))
    {
        return (mainIsKey && _currentView != nil) ? [_currentView canAction:ActionIDGoto] : NO;
    }
    if (theAction == @selector(handleGoToOriginal:))
    {
        return (mainIsKey && _currentView != nil) ? [_currentView canAction:ActionIDGotoOriginal] : NO;
    }
    if (theAction == @selector(handleGoToPreviousRoot:))
    {
        return (mainIsKey && _currentView != nil) ? [_currentView canAction:ActionIDGotoPreviousRoot] : NO;
    }
    if (theAction == @selector(handleGoToNextRoot:))
    {
        return (mainIsKey && _currentView != nil) ? [_currentView canAction:ActionIDGotoNextRoot] : NO;
    }
    if (theAction == @selector(handleReplyByMail:))
    {
        return (mainIsKey && _currentView != nil) ? [_currentView canAction:ActionIDReplyByMail] : NO;
    }
    if (theAction == @selector(delete:))
    {
        return (_currentView != nil) ? [_currentView canAction:ActionIDDelete] : NO;
    }
    if (theAction == @selector(handleForumManage:))
    {
        return (_currentView != nil) ? [_currentView canAction:ActionIDManage] : NO;
    }
    if (theAction == @selector(handleForumParticipants:))
    {
        return (_currentView != nil) ? [_currentView canAction:ActionIDParticipants] : NO;
    }
    if (theAction == @selector(handleWithdraw:))
    {
        BOOL enabled = (mainIsKey && _currentView != nil) ? [_currentView canAction:ActionIDWithdraw] : NO;
        if (enabled)
            [menuItem setTitle:[_currentView titleForAction:ActionIDWithdraw]];
        return enabled;
    }
    if (theAction == @selector(handleBlock:))
    {
        return (mainIsKey && _currentView != nil) ? [_currentView canAction:ActionIDBlock] : NO;
    }
    if (theAction == @selector(handleFolderDelete:))
    {
        FolderBase * folderBase = [foldersTree selection];
        return (mainIsKey && folderBase != nil && folderBase.canDelete);
    }
    if (theAction == @selector(handleFolderResign:))
    {
        FolderBase * folderBase = [foldersTree selection];
        return (mainIsKey && folderBase != nil && [folderBase isKindOfClass:TopicFolder.class] && ((TopicFolder *)folderBase).folder.canResign);
    }
    if (theAction == @selector(handleMarkAllRead:))
    {
        FolderBase * folderBase = [foldersTree selection];
        return (mainIsKey && folderBase != nil && [folderBase isKindOfClass:TopicFolder.class] && ((TopicFolder *)folderBase).canMarkAllRead);
    }
    if (theAction == @selector(handleMarkRead:))
    {
        BOOL enabled = (mainIsKey && _currentView != nil) ? [_currentView canAction:ActionIDMarkRead] : NO;
        if (enabled)
            [menuItem setTitle:[_currentView titleForAction:ActionIDMarkRead]];
        return enabled;
    }
    if (theAction == @selector(handleMarkReadThread:))
    {
        return (mainIsKey && _currentView != nil) ? [_currentView canAction:ActionIDMarkThreadRead] : NO;
    }
    if (theAction == @selector(handleMarkReadLock:))
    {
        BOOL enabled = (mainIsKey && _currentView != nil) ? [_currentView canAction:ActionIDMarkReadLock] : NO;
        if (enabled)
            [menuItem setTitle:[_currentView titleForAction:ActionIDMarkReadLock]];
        return enabled;
    }
    if (theAction == @selector(handleMarkStar:))
    {
        BOOL enabled = (mainIsKey && _currentView != nil) ? [_currentView canAction:ActionIDMarkStar] : NO;
        if (enabled)
            [menuItem setTitle:[_currentView titleForAction:ActionIDMarkStar]];
        return enabled;
    }
    if (theAction == @selector(handleMarkPriority:))
    {
        BOOL enabled = (mainIsKey && _currentView != nil) ? [_currentView canAction:ActionIDMarkPriority] : NO;
        if (enabled)
            [menuItem setTitle:[_currentView titleForAction:ActionIDMarkPriority]];
        return enabled;
    }
    if (theAction == @selector(handleMarkIgnore:))
    {
        BOOL enabled = (mainIsKey && _currentView != nil) ? [_currentView canAction:ActionIDMarkIgnore] : NO;
        if (enabled)
            [menuItem setTitle:[_currentView titleForAction:ActionIDMarkIgnore]];
        return enabled;
    }
    if (theAction == @selector(handleCopyLink:))
    {
        return (mainIsKey && _currentView != nil) ? [_currentView address] != nil : NO;
    }
    if (theAction == @selector(handleBiggerText:))
    {
        return (mainIsKey && _currentView != nil) ? [_currentView canAction:ActionIDBiggerText] : NO;
    }
    if (theAction == @selector(handleSmallerText:))
    {
        return (mainIsKey && _currentView != nil) ? [_currentView canAction:ActionIDSmallerText] : NO;
    }
    if (theAction == @selector(handleShowPlaintext:))
    {
        Preferences * prefs = [Preferences standardPreferences];
        [menuItem setState:[prefs ignoreMarkup] ? NSOnState : NSOffState];
        return YES;
    }
    if (theAction == @selector(handleShowInlineImages:))
    {
        Preferences * prefs = [Preferences standardPreferences];
        [menuItem setState:[prefs downloadInlineImages] ? NSOnState : NSOffState];
        return YES;
    }
    if (theAction == @selector(handleShowIgnored:))
    {
        Preferences * prefs = [Preferences standardPreferences];
        [menuItem setState:[prefs showIgnored] ? NSOnState : NSOffState];
        return YES;
    }
    if (theAction == @selector(handleGroupByConv:))
    {
        Preferences * prefs = [Preferences standardPreferences];
        [menuItem setState:[prefs groupByConv] ? NSOnState : NSOffState];
        return YES;
    }
    if (theAction == @selector(handleCollapseConv:))
    {
        Preferences * prefs = [Preferences standardPreferences];
        [menuItem setState:[prefs collapseConv] ? NSOnState : NSOffState];
        return YES;
    }
    if (theAction == @selector(handleEditMessage:))
    {
        return (mainIsKey && _currentView != nil) ? [_currentView canAction:ActionIDEditMessage] : NO;
    }
    if (theAction == @selector(handleRefresh:))
    {
        return (mainIsKey && [foldersTree selection] != nil);
    }
    return YES;
}

/* Return the matching NSToolbarItem for the identifier specified.
 */
-(NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    CRToolbarItem * item = [[CRToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    if ([itemIdentifier isEqualToString:@"NextUnread"])
    {
        [item setLabel:NSLocalizedString(@"Next Unread", nil)];
        [item setTarget:self];
        [item setAction:@selector(handleNextUnread:)];
        [item setToolTip:NSLocalizedString(@"Go to the next unread message", nil)];
        [item compositeButtonImage:@"tbNextUnread"];
        [item setPaletteLabel:[item label]];
    }
    else if ([itemIdentifier isEqualToString:@"Backtrack"])
    {
        [item setLabel:NSLocalizedString(@"Previous", nil)];
        [item setTarget:self];
        [item setAction:@selector(goBack:)];
        [item setToolTip:NSLocalizedString(@"Go back to the previous message", nil)];
        [item compositeButtonImage:@"tbPrevious"];
        [item setPaletteLabel:[item label]];
    }
    else if ([itemIdentifier isEqualToString:@"Read"])
    {
        [item setLabel:NSLocalizedString(@"Read", nil)];
        [item setTarget:self];
        [item setAction:@selector(handleMarkRead:)];
        [item setToolTip:NSLocalizedString(@"Toggle read status on the selected message", nil)];
        [item compositeButtonImage:@"tbRead"];
        [item setPaletteLabel:[item label]];
    }
    else if ([itemIdentifier isEqualToString:@"Star"])
    {
        [item setLabel:NSLocalizedString(@"Flag", nil)];
        [item setTarget:self];
        [item setAction:@selector(handleMarkStar:)];
        [item setToolTip:NSLocalizedString(@"Toggle flag on the selected message", nil)];
        [item compositeButtonImage:@"tbFlag"];
        [item setPaletteLabel:[item label]];
    }
    else if ([itemIdentifier isEqualToString:@"ReadLock"])
    {
        [item setLabel:NSLocalizedString(@"Read Lock", nil)];
        [item setTarget:self];
        [item setAction:@selector(handleMarkReadLock:)];
        [item setToolTip:NSLocalizedString(@"Toggle the read lock on the selected message", nil)];
        [item compositeButtonImage:@"tbReadLock"];
        [item setPaletteLabel:[item label]];
    }
    else if ([itemIdentifier isEqualToString:@"Withdraw"])
    {
        [item setLabel:NSLocalizedString(@"Withdraw", nil)];
        [item setTarget:self];
        [item setAction:@selector(handleWithdraw:)];
        [item setToolTip:NSLocalizedString(@"Delete or withdraw the selected message", nil)];
        [item compositeButtonImage:@"tbWithdraw"];
        [item setPaletteLabel:[item label]];
    }
    else if ([itemIdentifier isEqualToString:@"Join"])
    {
        [item setLabel:NSLocalizedString(@"Join Forum", nil)];
        [item setTarget:self];
        [item setAction:@selector(handleJoinForum:)];
        [item setToolTip:NSLocalizedString(@"Join a new forum", nil)];
        [item compositeButtonImage:@"tbJoin"];
        [item setPaletteLabel:[item label]];
    }
    else if ([itemIdentifier isEqualToString:@"NextUnreadPriority"])
    {
        [item setLabel:NSLocalizedString(@"Next Priority", nil)];
        [item setTarget:self];
        [item setAction:@selector(handleNextUnreadPriority:)];
        [item setToolTip:NSLocalizedString(@"Go to the next unread priority message", nil)];
        [item compositeButtonImage:@"tbNextUnreadPriority"];
        [item setPaletteLabel:[item label]];
    }
    else if ([itemIdentifier isEqualToString:@"Print"])
    {
        [item setLabel:NSLocalizedString(@"Print", nil)];
        [item setTarget:self];
        [item setAction:@selector(printDocument:)];
        [item setToolTip:NSLocalizedString(@"Print the current message", nil)];
        [item compositeButtonImage:@"tbPrint"];
        [item setPaletteLabel:[item label]];
    }
    else if ([itemIdentifier isEqualToString:@"NewMail"])
    {
        [item setLabel:NSLocalizedString(@"New PMessage", nil)];
        [item setTarget:self];
        [item setAction:@selector(handleNewMail:)];
        [item setToolTip:NSLocalizedString(@"Compose and send a new pmessage", nil)];
        [item compositeButtonImage:@"tbNewMail"];
        [item setPaletteLabel:[item label]];
    }
    else if ([itemIdentifier isEqualToString:@"Reply"])
    {
        [item setLabel:NSLocalizedString(@"Reply To Message", nil)];
        [item setTarget:self];
        [item setAction:@selector(handleReply:)];
        [item setToolTip:NSLocalizedString(@"Compose a reply to the selected message", nil)];
        [item compositeButtonImage:@"tbReply"];
        [item setPaletteLabel:[item label]];
    }
    else if ([itemIdentifier isEqualToString:@"NewMessage"])
    {
        [item setLabel:NSLocalizedString(@"New Message", nil)];
        [item setTarget:self];
        [item setAction:@selector(handleNewMessage:)];
        [item setToolTip:NSLocalizedString(@"Start a new thread in the current topic", nil)];
        [item compositeButtonImage:@"tbNewMessage"];
        [item setPaletteLabel:[item label]];
    }
    else if ([itemIdentifier isEqualToString:@"Quote"])
    {
        [item setLabel:NSLocalizedString(@"Quote Message", nil)];
        [item setTarget:self];
        [item setAction:@selector(quoteOriginal:)];
        [item setToolTip:NSLocalizedString(@"Reply and quote the selected message", nil)];
        [item compositeButtonImage:@"tbQuote"];
        [item setPaletteLabel:[item label]];
    }
    else if ([itemIdentifier isEqualToString:@"Profile"])
    {
        [item setLabel:NSLocalizedString(@"View Profile", nil)];
        [item setTarget:self];
        [item setAction:@selector(handleShowProfile:)];
        [item setToolTip:NSLocalizedString(@"View the profile of the message author", nil)];
        [item compositeButtonImage:@"tbProfile"];
        [item setPaletteLabel:[item label]];
    }
    else if ([itemIdentifier isEqualToString:@"Offline"])
    {
        [item setLabel:NSLocalizedString(@"Offline", nil)];
        [item setTarget:self];
        [item setAction:@selector(toggleOffline:)];
        [item setToolTip:NSLocalizedString(@"Toggle online/offline state", nil)];
        [item compositeButtonImage:@"tbOnline"];
        [item setPaletteLabel:[item label]];
    }
    else if ([itemIdentifier isEqualToString:@"SearchBar"])
    {
        [item setLabel:NSLocalizedString(@"Search", nil)];
        [item setPaletteLabel:item.label];
        [item setToolTip:NSLocalizedString(@"Search Messages", nil)];
        [item setTarget:self];
        [item setAction:@selector(searchUsingSearchPanel:)];
        
        [item setView:searchFieldOutlet];
        [item setMinSize:NSMakeSize(100, NSHeight([searchFieldOutlet frame]))];
        [item setMaxSize:NSMakeSize(400, NSHeight([searchFieldOutlet frame]))];
    }
    return item;
}

/* Default toolbar items
 */
-(NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    return @[ @"Join",
              @"Print",
              NSToolbarSpaceItemIdentifier,
              @"NewMessage",
              @"Reply",
              NSToolbarSpaceItemIdentifier,
              @"Backtrack",
              @"NextUnread",
              @"NextUnreadPriority",
              NSToolbarSpaceItemIdentifier,
              @"Read",
              @"Star",
              @"ReadLock",
              NSToolbarFlexibleSpaceItemIdentifier,
              @"SearchBar" ];
}

/* All possible toolbar items.
 */
-(NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    return @[ NSToolbarFlexibleSpaceItemIdentifier,
              NSToolbarSeparatorItemIdentifier,
              NSToolbarSpaceItemIdentifier,
              @"NewMail",
              @"NewMessage",
              @"Reply",
              @"Quote",
              @"NextUnread",
              @"Backtrack",
              @"NextUnreadPriority",
              @"Read",
              @"Star",
              @"Withdraw",
              @"ReadLock",
              @"Join",
              @"Profile",
              @"Print",
              @"Offline",
              @"SearchBar" ];
}
@end
