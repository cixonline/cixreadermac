//
//  UserForumEditor.m
//  CIXReader
//
//  Created by Steve Palmer on 19/01/2015.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "UserForumEditor.h"
#import "StringExtensions.h"
#import "CRWordInputValidator.h"
#import "CIX.h"

@implementation UserForumEditor

/* Fill out the table with the existing list of users.
 */
-(void)awakeFromNib
{
    if (!_didInitialise2)
    {
        [self loadList];
        
        // Show Loading view if the list is empty
        if (_users.count == 0 && CIX.online)
        {
            [spinner startAnimation:self];
            [loadingView setHidden:NO];
        }
        
        [removeButton setEnabled:NO];

        // Grey attributed string
        greyAttr = @{ NSForegroundColorAttributeName : [NSColor grayColor] };
        
        // Register for notifications
        NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:nil];
        [nc addObserver:self selector:@selector(handleTextDidChange:) name:NSControlTextDidChangeNotification object:addTextField];

        [tableView reloadData];
        
        _didInitialise2 = YES;
    }
}

-(void)setUserList:(NSArray *)list
{
    _list = list;
}

-(void)setAddList:(NSArray *)list
{
    _toAdd = [NSMutableArray arrayWithArray:list];
}

-(void)setRemoveList:(NSArray *)list
{
    _toRemove = [NSMutableArray arrayWithArray:list];
}

-(void)windowWillClose:(NSNotification *)notification
{
    MultiViewController * parent = [[NSApp modalWindow] windowController];
    [parent closeAllViews:NO];
}

/* List updated so reload the data.
 */
-(void)updateList
{
    [self loadList];
    [spinner stopAnimation:self];
    [loadingView setHidden:YES];
    [tableView reloadData];
}

/* Handle the selection changing in the table view.
 */
-(void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    [self updateRemoveButton];
}

-(void)updateRemoveButton
{
    NSInteger row = tableView.selectedRow;
    if (row >= 0 && [_toRemove containsObject:_users[row]])
        [removeButton setTitle:NSLocalizedString(@"Restore", nil)];
    else
        [removeButton setTitle:NSLocalizedString(@"Remove", nil)];
    [removeButton setEnabled:row >= 0];
}

/* Load the full users list by merging the active list of users
 * with the list of names being added.
 */
-(void)loadList
{
    NSMutableArray * users = [NSMutableArray array];
    for (NSString * name in _list)
        [users addObject:name];
    for (NSString * name in _toAdd)
        [users addObject:name];
    
    _users = [NSArray arrayWithArray:[users sortedArrayUsingSelector:@selector(localizedCompare:)]];
}

/* Datasource for the table view. Return the total number of users.
 */
-(NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [_users count];
}

/* Called by the table view to obtain the object at the specified column and row. This is
 * called often so it needs to be fast.
 */
-(id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    NSString * username = _users[rowIndex];
    
    if ([aTableColumn.identifier isEqualToString:@"imageCell"])
    {
        Mugshot * mugshot = [Mugshot mugshotForUser:username withRefresh:NO];
        return mugshot.image;
    }
    
    NSMutableAttributedString * name = [[NSMutableAttributedString alloc] initWithString:username];
    if ([_toAdd containsObject:username])
    {
        NSAttributedString * addedString = [[NSAttributedString alloc] initWithString:NSLocalizedString(@" (added)", nil) attributes:greyAttr];
        [name appendAttributedString:addedString];
    }
    if ([_toRemove containsObject:username])
    {
        NSAttributedString * removedString = [[NSAttributedString alloc] initWithString:NSLocalizedString(@" (removed)", nil) attributes:greyAttr];
        [name appendAttributedString:removedString];
    }
    return name;
}

/* Handle the add button to bring up a sheet to enter a user name.
 */
-(IBAction)handleAddButton:(id)sender
{
    [addPanelAddButton setEnabled:NO];
    
    CRWordInputValidator * formatter = [[CRWordInputValidator alloc] init];
    [addTextField setFormatter:formatter];
    [addTextField setStringValue:@""];
    
    [[tableView window] beginSheet:addPanel completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSModalResponseOK)
        {
            NSString * name = [addTextField stringValue];
            
            if (![_toAdd containsObject:name] && ![_list containsObject:name])
                [_toAdd addObject:name];
            
            [self loadList];
            [tableView reloadData];
            [self updateRemoveButton];
            
            // Select the newly added user for convenience.
            NSInteger row = [_users indexOfObject:name];
            [tableView selectRowIndexes: [NSIndexSet indexSetWithIndex:(NSUInteger)row] byExtendingSelection:NO];
            [tableView scrollRowToVisible:row];
        }
        [addPanel orderOut:self];
        [[tableView window] makeKeyAndOrderFront:self];
    }];
}

/* Just close the add panel.
 */
-(IBAction)handleAddPanelCancelButton:(id)sender
{
    [[tableView window] endSheet:addPanel returnCode:NSModalResponseCancel];
}

/* Called when the user clicks Add
 */
-(IBAction)handleAddPanelAddButton:(id)sender
{
    [[tableView window] endSheet:addPanel returnCode:NSModalResponseOK];
}

/* This function is called when the contents of the title field is changed.
 * We disable the Save button if the title field is empty or enable it otherwise.
 */
-(void)handleTextDidChange:(NSNotification *)aNotification
{
    NSString * name = [addTextField stringValue];
    [addPanelAddButton setEnabled:![name isBlank]];
}

/* Handle the remove button to remove the selected user.
 */
-(IBAction)handleRemoveButton:(id)sender
{
    NSInteger row = tableView.selectedRow;
    NSString * name = _users[row];
    
    if ([_toAdd containsObject:name])
        [_toAdd removeObject:name];
    else if ([_toRemove containsObject:name])
        [_toRemove removeObject:name];
    else
        [_toRemove addObject:name];
    
    [self loadList];
    [tableView reloadData];
    [self updateRemoveButton];
}

/* Close the view and save any changes.
 */
-(BOOL)closeView:(BOOL)response
{
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:NSWindowWillCloseNotification object:nil];
    [nc removeObserver:self name:NSControlTextDidChangeNotification object:nil];
    
    [tableView setDataSource:nil];
    [tableView setDelegate:nil];
    return YES;
}

/* Save changes back to the forum object and then commit them.
 */
-(IBAction)handleSaveButton:(id)sender
{
    MultiViewController * parent = [[NSApp modalWindow] windowController];
    [parent closeAllViews:YES];
}

/* Exit without saving any changes.
 */
-(IBAction)handleCancelButton:(id)sender
{
    MultiViewController * parent = [[NSApp modalWindow] windowController];
    [parent closeAllViews:NO];
}
@end
