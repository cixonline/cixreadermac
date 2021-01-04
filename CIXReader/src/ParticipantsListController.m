//
//  ParticipantsListController.m
//  CIXReader
//
//  Created by Steve Palmer on 20/01/2015.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "ParticipantsListController.h"
#import "UserCellView.h"
#import "Mugshot.h"
#import "ProfileController.h"

@implementation ParticipantsListController

/* Initialise with the specified forum.
 */
-(id)initWithForum:(DirForum *)forum
{
    if ((self = [super initWithWindowNibName:@"ParticipantsList"]) != nil)
        _forum = forum;
    return self;
}

-(void)awakeFromNib
{
    if (!_didInitialise)
    {
        [self loadList];
        
        // Show Loading view if the list is empty
        if (_participants.count == 0 && CIX.online)
        {
            [spinner startAnimation:self];
            [loadingView setHidden:NO];
        }
        
        NSString * title = [NSString stringWithFormat:NSLocalizedString(@"Participants in %@", nil), _forum.name];
        [self.window setTitle:title];

        // Refresh the participant list anyway
        [_forum refresh];

        [tableList setDoubleAction:@selector(handleViewProfile:)];
        [tableList setTarget:self];

        [viewProfileButton setEnabled:NO];
        
        NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:nil];
        [nc addObserver:self selector:@selector(handleParticipantsUpdated:) name:MAParticipantsUpdated object:nil];
        
        [tableList reloadData];
        _didInitialise = YES;
    }
}

-(void)windowWillClose:(NSNotification *)notification
{
    [NSApp stopModalWithCode:NO];
}

/* Invoked when the participants list is refreshed.
 */
-(void)handleParticipantsUpdated:(NSNotification *)notification
{
    [spinner stopAnimation:self];
    [loadingView setHidden:YES];

    [self loadList];
    
    [tableList reloadData];
}

-(void)loadList
{
    _participants = [NSArray arrayWithArray:[_forum participants]];
    [countText setStringValue:[NSString stringWithFormat:NSLocalizedString(@"%ld participants", nil), _participants.count]];
}

/* Handle the selection changing in the table view.
 */
-(void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    NSInteger index = tableList.selectedRow;
    [viewProfileButton setEnabled:index >= 0];
}

/* Datasource for the table view. Return the total number of participants in the
 * _participants array.
 */
-(NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [_participants count];
}

/* Render the view for each column of the table. There's just one column so this does the
 * whole row.
 */
-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    UserCellView * result = [tableView makeViewWithIdentifier:@"userCell" owner:nil];
    if (row >= 0 && row < _participants.count)
    {
        NSString * user = _participants[row];
        if (result != nil)
        {
            Mugshot * mugshot = [Mugshot mugshotForUser:user withRefresh:NO];
            
            [result.image setCircleDiameter:22];
            result.image.image = mugshot.image;
            
            result.user.textColor = [NSColor textColor];
            result.user.stringValue = user;
        }
    }
    return result;
}

/* Handle the button to display the selected user's profile.
 */
-(IBAction)handleViewProfile:(id)sender
{
    NSInteger row = tableList.selectedRow;
    if (row >= 0 && row < _participants.count)
    {
        Profile * profile = [Profile profileForUser:_participants[row]];
        if (profile != nil)
        {
            ProfileController * profileController = [[ProfileController alloc] initWithProfile:profile];
            NSWindow * profileWindow = [profileController window];
            
            [NSApp runModalForWindow:profileWindow];
            [NSApp endSheet:profileWindow];
            [profileWindow orderOut: self];
        }
    }
}

/* Handle the Close button
 */
-(IBAction)handleClose:(id)sender
{
    [NSApp stopModalWithCode:NO];
}
@end
