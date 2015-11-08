//
//  DirectoryView.m
//  CIXReader
//
//  Created by Steve Palmer on 25/08/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "CIX.h"
#import "DirectoryView.h"
#import "AppDelegate.h"
#import "Preferences.h"
#import "StringExtensions.h"
#import "CRLevelCell.h"
#import "CRTextCountCell.h"
#import "DirCategory.h"
#import "JoinForumController.h"

@implementation DirectoryView

/* Override initialisation to create an empty currentList array
 */
-(id)init
{
    if ((self = [super initWithNibName:@"DirectoryView" bundle:nil]) != nil)
    {
        [super initSorting:Sort_Popularity ascending:NO];
        _currentList = [[NSMutableArray alloc] init];
        _lockImage = [NSImage imageNamed:@"lock.tiff"];
    }
    return self;
}

/* Do the things that only make sense once the NIB is loaded.
 */
-(void)awakeFromNib
{
    if (!_didInitialise)
    {
        [self setDirectoryFont];
        
        // Set up columns for sorting
        NSTableColumn * tableColumn = [forumsList tableColumnWithIdentifier:@"Name"];
        [tableColumn.headerCell setTag:Sort_Name];

        tableColumn = [forumsList tableColumnWithIdentifier:@"Title"];
        [tableColumn.headerCell setTag:Sort_Title];
        
        tableColumn = [forumsList tableColumnWithIdentifier:@"SubCategory"];
        [tableColumn.headerCell setTag:Sort_SubCategory];
        
        tableColumn = [forumsList tableColumnWithIdentifier:@"Popularity"];
        [tableColumn.headerCell setTag:Sort_Popularity];
        
        [forumsList sizeLastColumnToFit];
        [forumsList setDoubleAction:@selector(doubleClickAction:)];
        [forumsList setTarget:self];

        // Register for notifications
        NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(handleDirectoryFontChange:) name:MA_Notify_ArticleListFontChange object:nil];
        [nc addObserver:self selector:@selector(handleDirectoryChanged:) name:MADirectoryChanged object:nil];
        [nc addObserver:self selector:@selector(handleDirectoryRefreshStarted:) name:MADirectoryRefreshStarted object:nil];
        [nc addObserver:self selector:@selector(handleDirectoryRefreshCompleted:) name:MADirectoryRefreshCompleted object:nil];
        
        _didInitialise = YES;
    }
}

/* Display the view for the specified folder. The folder is assumed to be a
 * CategoryFolder, otherwise this does nothing.
 */
-(BOOL)viewFromFolder:(FolderBase *)folder withAddress:(Address *)address options:(FolderOptions)options
{
    if (folder.viewForFolder == AppViewDirectory)
    {
        _currentCategory = (CategoryFolder *)folder;
        _currentList = [NSMutableArray arrayWithArray:_currentCategory.items];
        
        [self sortConversations:YES];
    }
    return YES;
}

/* Return the Sort menu for this view from the XIB.
 */
-(NSMenu *)sortMenu
{
    return sortMenu;
}

/* Sort the conversations using the specified ordering.
 */
-(void)sortConversations:(BOOL)update
{
    NSArray * recentArray = @[ [self sortDescriptorForOrder:_currentSortOrder] ];
    [_currentList sortUsingDescriptors:recentArray];
    [self showSortDirection];
    [forumsList reloadData];
    
    [super sortConversations:update];
}

/* Shows the current sort column and direction in the table.
 */
-(void)showSortDirection
{
    for (NSTableColumn * column in forumsList.tableColumns)
    {
        if ([column.headerCell tag] == _currentSortOrder)
        {
            NSString * imageName = _sortAscending ? @"NSAscendingSortIndicator" : @"NSDescendingSortIndicator";
            [forumsList setHighlightedTableColumn:column];
            [forumsList setIndicatorImage:[NSImage imageNamed:imageName] inTableColumn:column];
        }
        else
            [forumsList setIndicatorImage:nil inTableColumn:column];
    }
}

/* Return a sort descriptor for the specified order.
 */
-(NSSortDescriptor *)sortDescriptorForOrder:(NSInteger)order
{
    NSString * keyName;
    SEL sel = NULL;
    switch (_currentSortOrder)
    {
        case Sort_Title:
            keyName = @"title";
            sel = @selector(localizedCompare:);
            break;
            
        case Sort_Name:
            keyName = @"name";
            sel = @selector(localizedCompare:);
            break;
            
        case Sort_SubCategory:
            keyName = @"sub";
            sel = @selector(localizedCompare:);
            break;
            
        case Sort_Popularity:
            keyName = @"recent";
            sel = @selector(compare:);
            break;
            
        default:
            NSAssert(false, @"Invalid _currentSortOrder");
            break;
    }
    return [NSSortDescriptor sortDescriptorWithKey:keyName ascending:_sortAscending selector:sel];
}

/* Handle the user click in the column header to sort by that column.
 * Clicking on the column currently being sorted again reverses the direction.
 */
-(void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn
{
    if (_currentSortOrder == [tableColumn.headerCell tag])
        _sortAscending = !_sortAscending;
    else
        _currentSortOrder = [tableColumn.headerCell tag];
    [self sortConversations:YES];
}

/* Called when the user changes the directory font and/or size in the Preferences
 */
-(void)handleDirectoryFontChange:(NSNotification *)notification
{
	[self setDirectoryFont];
	[forumsList reloadData];
}

/* A complete refresh of the directory has started.
 */
-(void)handleDirectoryRefreshStarted:(NSNotification *)notification
{
    AppDelegate * app = (AppDelegate *)[NSApp delegate];
    [app setStatusMessage:NSLocalizedString(@"Updating directory...", nil) persist:YES];
    [app startProgressIndicator];
}

/* A refresh of the directory has completed.
 */
-(void)handleDirectoryRefreshCompleted:(NSNotification *)notification
{
    AppDelegate * app = (AppDelegate *)[NSApp delegate];
    [app setStatusMessage:nil persist:YES];
    [app stopProgressIndicator];
    
    if ([_currentCategory.name isEqualToString:[CategoryFolder allCategoriesName]])
    {
        _currentList = [NSMutableArray arrayWithArray:_currentCategory.items];
        [self sortConversations:YES];
    }
}

/* Called when the directory changes. The object var is the category name which has
 * changed (or nil if all categories are affected).
 */
-(void)handleDirectoryChanged:(NSNotification *)notification
{
    @synchronized(self) {
        NSString * categoryName = notification.object;
        if ([categoryName isEqualToString:_currentCategory.name])
        {
            _currentList = [NSMutableArray arrayWithArray:_currentCategory.items];
            [self sortConversations:YES];
        }
    }
}

/* Creates or updates the fonts used by the directory.
 */
-(void)setDirectoryFont
{
	Preferences * prefs = [Preferences standardPreferences];
	_cellFont = [NSFont fontWithName:[prefs articleListFont] size:[prefs articleListFontSize]];
}

/* We handle the Join action ID if we have a selection.
 */
-(BOOL)canAction:(ActionID)actionID
{
    return actionID == ActionIDJoin && forumsList.selectedRow >= 0;
}

/* Respond to the Join action
 */
-(void)action:(ActionID)actionID
{
    if ([self canAction:actionID])
    {
        DirForum * forum = _currentList[forumsList.selectedRow];
        [self joinForum:forum];
    }
}

/* Handle a double-click to open a forum. If the forum is local then we go to
 * the forum home page, otherwise we get the option to Join that forum.
 */
-(void)doubleClickAction:(id)sender
{
    DirForum * forum = _currentList[forumsList.selectedRow];
    AppDelegate * app = (AppDelegate *)[NSApp delegate];
    [app setAddress:[NSString stringWithFormat:@"cix:%@", forum.name]];
}

/* Handle the Join button action.
 */
-(IBAction)handleJoinButton:(id)sender
{
    NSButton * button = (NSButton *)sender;
    DirForum * forum = _currentList[button.tag];
    [self joinForum:forum];
}

-(void)joinForum:(DirForum *)forum
{
    JoinForumController * joinForumController = [[JoinForumController alloc] initWithName:forum.name];
    NSWindow * joinForumWindow = [joinForumController window];
    
    [joinForumWindow center];
    
    [NSApp runModalForWindow:joinForumWindow];
    [NSApp endSheet:joinForumWindow];
    [joinForumWindow orderOut: self];
}

/* Invoked when the user enters something in the search filter.
 */
-(void)filterViewByString:(NSString *)searchString
{
    _currentList = [NSMutableArray arrayWithArray:_currentCategory.items];
    
    if (![searchString isBlank])
    {
        NSPredicate * bPredicate =[NSPredicate predicateWithFormat:@"(SELF.title contains[cd] %@) OR (SELF.name contains[cd] %@)", searchString, searchString];
        [_currentList filterUsingPredicate:bPredicate];
    }

    // Re-sort using the current sort order set in the UI
    [_currentList sortUsingDescriptors:[forumsList sortDescriptors]];
    [forumsList reloadData];
}

/* Return the count in the current list of forums in the table.
 */
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return _currentList.count;
}

/* Display each column of the table.
 */
-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    DirForum * forum = _currentList[row];

    if ([[tableColumn identifier] isEqualToString:@"Name"])
    {
        NSTableCellView * result = [tableView makeViewWithIdentifier:@"nameCell" owner:self];
        result.imageView.image = ([forum.type isEqualToString:@"c"]) ? _lockImage : nil;
        result.textField.stringValue = forum.name;
        result.textField.font = _cellFont;
        return result;
    }
    if ([[tableColumn identifier] isEqualToString:@"Title"])
    {
        NSTableCellView * result = [tableView makeViewWithIdentifier:@"titleCell" owner:self];
        result.textField.stringValue = forum.title;
        result.textField.font = _cellFont;
        return result;
    }

    // Popularity of a forum is computed based on the number of recent messages where
    // simply anything 500 or more is 5-star.
    if ([[tableColumn identifier] isEqualToString:@"Popularity"])
    {
        CRLevelCell * result = [tableView makeViewWithIdentifier:@"recentCell" owner:self];
        result.levelIndicator.doubleValue = MIN((forum.recent + 100)/100, 5);
        return result;
    }
    
    // Show the sub-category.
    if ([[tableColumn identifier] isEqualToString:@"SubCategory"])
    {
        CRLevelCell * result = [tableView makeViewWithIdentifier:@"subcategoryCell" owner:self];
        result.textField.stringValue = forum.sub;
        result.textField.font = _cellFont;
        return result;
    }
    
    // Hide Join button if we're already a member of this forum.
    if ([[tableColumn identifier] isEqualToString:@"Join"])
    {
        CRTextCountCell * result = [tableView makeViewWithIdentifier:@"joinCell" owner:self];
        [result setButtonStyle:NSRoundedBezelStyle];
        [result.button setHidden:[CIX.folderCollection isJoined:forum.name]];
        [result.button setTag:row];
        return result;
    }
    return nil;
}
@end
