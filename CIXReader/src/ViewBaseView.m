//
//  ViewBaseView.m
//  CIXReader
//
//  Created by Steve Palmer on 08/10/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "ViewBaseView.h"
#import "Preferences.h"

@implementation ViewBaseView

// Deprecated in 1.42 but need to preserve the value
#define Sort_Conversation   8

-(void)initSorting:(NSInteger)order ascending:(BOOL)flag
{
    Preferences * prefs = [Preferences standardPreferences];
    
    _sortOrderPreference = [NSString stringWithFormat:@"%@_SortOrder", self.class];
    _sortDirectionPreference = [NSString stringWithFormat:@"%@_SortDirection", self.class];
    
    _currentSortOrder = order;
    _sortAscending = flag;
    
    if ([prefs hasKey:_sortOrderPreference])
        _currentSortOrder = [prefs integerForKey:_sortOrderPreference];
    if ([prefs hasKey:_sortDirectionPreference])
        _sortAscending = [prefs boolForKey:_sortDirectionPreference];

    // Conversation changed to a grouping in 1.42
    if (_currentSortOrder == Sort_Conversation)
        _currentSortOrder = Sort_Date;
}

/* Does nothing.
 */
-(BOOL)viewFromFolder:(FolderBase *)folder withAddress:(Address *)address options:(FolderOptions)options
{
    return YES;
}

/* Return whether the view can action the specified Action ID.
 */
-(BOOL)canAction:(ActionID)actionID
{
    return NO;
}

/* No image for action.
 */
-(NSString *)imageForAction:(ActionID)actionID
{
    return @"";
}

/* No title for action.
 */
-(NSString *)titleForAction:(ActionID)actionID
{
    return @"";
}

/* Carry out the specified Action ID.
 */
-(void)action:(ActionID)actionID
{
}

/* Default doesn't handle any scheme.
 */
-(BOOL)handles:(NSString *)scheme
{
    return NO;
}

/* Default has no address.
 */
-(NSString *)address
{
    return nil;
}

/* Default has no Sort menu.
 */
-(NSMenu *)sortMenu
{
    return nil;
}

/* Default has no title.
 */
-(NSString *)title
{
    return @"";
}

/* Respond to the user changing the view sort direction.
 */
-(IBAction)sortDirectionChanged:(id)sender
{
    _sortAscending = ([sender tag] == Sort_Ascending);
    [self sortConversations:YES];
}

/* Respond to the user changing the view sort order.
 */
-(IBAction)sortOrderChanged:(id)sender
{
    NSMenuItem * selected = (NSMenuItem *)sender;
    if (selected != nil)
    {
        _currentSortOrder = [selected tag];
        [self sortConversations:YES];
    }
}

/* Default does no sorting.
 */
-(void)sortConversations:(BOOL)update
{
    Preferences * prefs = [Preferences standardPreferences];
    [prefs setInteger:_currentSortOrder forKey:_sortOrderPreference];
    [prefs setBool:_sortAscending forKey:_sortDirectionPreference];
}

/* Search does nothing
 */
-(void)filterViewByString:(NSString *)string
{
}

/* Do the menu initialisation when the user pulls down a menu item.
 */
-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    SEL theAction = [menuItem action];
    if (theAction == @selector(sortOrderChanged:))
    {
        [menuItem setState:(_currentSortOrder == [menuItem tag]) ? NSOnState : NSOffState];
        return YES;
    }
    if (theAction == @selector(sortDirectionChanged:))
    {
        [menuItem setState:((_sortAscending ? Sort_Ascending : Sort_Descending) == [menuItem tag]) ? NSOnState : NSOffState];
        return YES;
    }
    return NO;
}
@end

