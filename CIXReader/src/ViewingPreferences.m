//
//  ViewingPreferences.m
//  CIXReader
//
//  Created by Steve Palmer on 21/09/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "ViewingPreferences.h"
#import "Preferences.h"

// List of available font sizes. I picked the ones that matched
// Mail but you easily could add or remove from the list as needed.
int availableFontSizes[] = { 6, 8, 9, 10, 11, 12, 14, 16, 18, 20, 24, 32, 48, 64 };

// List of minimum font sizes. I picked the ones that matched the same option in
// Safari but you easily could add or remove from the list as needed.
int availableMinimumFontSizes[] = { 9, 10, 11, 12, 14, 18, 24 };

// Private functions
@interface ViewingPreferences (Private)
-(void)initializePreferences;
-(void)selectUserDefaultFont:(NSString *)name size:(int)size control:(NSTextField *)control;
@end

@implementation ViewingPreferences

/* Initialize the class
 */
-(id)initWithObject:(id)data
{
    return [super initWithNibName:@"ViewingPreferences" bundle:nil];
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
        
        // Set up to be notified if preferences change outside this window
        NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(handleReloadPreferences:) name:MA_Notify_FolderFontChange object:nil];
        [nc addObserver:self selector:@selector(handleReloadPreferences:) name:MA_Notify_ArticleListFontChange object:nil];
        [nc addObserver:self selector:@selector(handleReloadPreferences:) name:MA_Notify_MessageFontChange object:nil];
        [nc addObserver:self selector:@selector(handleReloadPreferences:) name:MA_Notify_StyleChange object:nil];
        _didInitialise = YES;
    }
}

/* handleReloadPreferences
 * This gets called when MA_Notify_PreferencesUpdated is broadcast. Just update the controls values.
 */
-(void)handleReloadPreferences:(NSNotification *)nc
{
    [self initializePreferences];
}

/* Set the preference settings from the user defaults.
 */
-(void)initializePreferences
{
    if (!_skipInit)
    {
        Preferences * prefs = [Preferences standardPreferences];
        
        // Populate the drop downs with the font names and sizes
        [self selectUserDefaultFont:[prefs articleListFont] size:[prefs articleListFontSize] control:articleFontSample];
        [self selectUserDefaultFont:[prefs folderListFont] size:[prefs folderListFontSize] control:folderFontSample];
        [self selectUserDefaultFont:[prefs messageFont] size:[prefs messageFontSize] control:messageFontSample];
        
        _stylesController = [[StyleController alloc] init];
        [stylesList addItemsWithTitles:[_stylesController.allStyles sortedArrayUsingSelector:@selector(localizedCompare:)]];
        [stylesList selectItemWithTitle:prefs.displayStyle];
    }
}

/* Respond to the user changing the default style.
 */
-(void)stylesListChanged:(id)sender
{
    _skipInit = YES;
    Preferences * prefs = [Preferences standardPreferences];
    [prefs setDisplayStyle:stylesList.selectedItem.title];
    _skipInit = NO;
}

/* Display sample text in the specified font and size.
 */
-(void)selectUserDefaultFont:(NSString *)name size:(int)size control:(NSTextField *)control
{
    [control setFont:[NSFont fontWithName:name size:11]];
    [control setStringValue:[NSString stringWithFormat:@"%@ %i", name, size]];
}

/* Bring up the standard font selector for the article font.
 */
-(IBAction)selectArticleFont:(id)sender
{
    Preferences * prefs = [Preferences standardPreferences];
    NSFontManager * manager = [NSFontManager sharedFontManager];
    [manager setSelectedFont:[NSFont fontWithName:[prefs articleListFont] size:[prefs articleListFontSize]] isMultiple:NO];
    [manager setAction:@selector(changeArticleFont:)];
    [manager orderFrontFontPanel:self];
}

/* Bring up the standard font selector for the folder font.
 */
-(IBAction)selectFolderFont:(id)sender
{
    Preferences * prefs = [Preferences standardPreferences];
    NSFontManager * manager = [NSFontManager sharedFontManager];
    [manager setSelectedFont:[NSFont fontWithName:[prefs folderListFont] size:[prefs folderListFontSize]] isMultiple:NO];
    [manager setAction:@selector(changeFolderFont:)];
    [[folderFontSample window] makeFirstResponder:self];
    [manager orderFrontFontPanel:self];
}

/* Bring up the standard font selector for the message font.
 */
-(IBAction)selectMessageFont:(id)sender
{
    Preferences * prefs = [Preferences standardPreferences];
    NSFontManager * manager = [NSFontManager sharedFontManager];
    [manager setSelectedFont:[NSFont fontWithName:[prefs messageFont] size:[prefs messageFontSize]] isMultiple:NO];
    [manager setAction:@selector(changeMessageFont:)];
    [[folderFontSample window] makeFirstResponder:self];
    [manager orderFrontFontPanel:self];
}

/* Respond to changes to the article font.
 */
-(IBAction)changeArticleFont:(id)sender
{
    Preferences * prefs = [Preferences standardPreferences];
    NSFont * font = [NSFont fontWithName:[prefs articleListFont] size:[prefs articleListFontSize]];
    font = [sender convertFont:font];
    [prefs setArticleListFont:[font fontName]];
    [prefs setArticleListFontSize:[font pointSize]];
    [self selectUserDefaultFont:[prefs articleListFont] size:[prefs articleListFontSize] control:articleFontSample];
}

/* Respond to changes to the folder font.
 */
-(IBAction)changeFolderFont:(id)sender
{
    Preferences * prefs = [Preferences standardPreferences];
    NSFont * font = [NSFont fontWithName:[prefs folderListFont] size:[prefs folderListFontSize]];
    font = [sender convertFont:font];
    [prefs setFolderListFont:[font fontName]];
    [prefs setFolderListFontSize:[font pointSize]];
    [self selectUserDefaultFont:[prefs folderListFont] size:[prefs folderListFontSize] control:folderFontSample];
}

/* Respond to changes to the message font.
 */
-(IBAction)changeMessageFont:(id)sender
{
    Preferences * prefs = [Preferences standardPreferences];
    NSFont * font = [NSFont fontWithName:[prefs messageFont] size:[prefs messageFontSize]];
    font = [sender convertFont:font];
    [prefs setMessageFont:[font fontName]];
    [prefs setMessageFontSize:[font pointSize]];
    [self selectUserDefaultFont:[prefs messageFont] size:[prefs messageFontSize] control:messageFontSample];
}
@end
