//
//  ForumsView.m
//  CIXReader
//
//  Created by Steve Palmer on 15/08/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "CIX.h"
#import "ForumsView.h"
#import "StringExtensions.h"
#import "DateExtensions.h"
#import "CategoryFolder.h"
#import "ModeratorItem.h"
#import "AppDelegate.h"
#import "MultiViewController.h"
#import "JoinForumController.h"
#import "ParticipantsListController.h"

@implementation ForumsView

/* Initialise the forums view.
 */
-(id)init
{
    return [super initWithNibName:@"ForumsView" bundle:nil];
}

/* Display the view for the specified folder. The folder is assumed to be a
 * TopicFolder, otherwise this does nothing.
 */
-(BOOL)viewFromFolder:(FolderBase *)folder withAddress:(Address *)address options:(FolderOptions)options
{
    if (folder.viewForFolder == AppViewForum)
    {
        _currentFolder = (TopicFolder *)folder;
        _forum = nil;
        [arrayController setContent:nil];

        if (_forum == nil)
            _forum = [CIX.directoryCollection forumByName:_currentFolder.name];

        [CIX.directoryCollection refreshForum:_currentFolder.name];
        [self refreshForumView];

        [_forum getDateOfLatestMessage];
        
        [[self.view window] makeFirstResponder:self.view];
    }
    return YES;
}

/* Do the things that only make sense once the NIB is loaded.
 */
-(void)awakeFromNib
{
    if (!_didInitialise)
    {
        // Register for notifications
        NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(handleForumChanged:) name:MAForumChanged object:nil];
        [nc addObserver:self selector:@selector(handleFolderRefreshed:) name:MAFolderRefreshed object:nil];
        [nc addObserver:self selector:@selector(handleModeratorsUpdated:) name:MAModeratorsUpdated object:nil];
        [nc addObserver:self selector:@selector(handleMugshotUpdated:) name:MAUserMugshotChanged object:nil];
        [nc addObserver:self selector:@selector(handleForumJoinedOrResigned:) name:MAForumResigned object:nil];
        [nc addObserver:self selector:@selector(handleForumJoinedOrResigned:) name:MAForumJoined object:nil];
        [nc addObserver:self selector:@selector(handleForumLatestDate:) name:MAForumLatestDate object:nil];
        
        _didInitialise = YES;
    }
}

/* Respond to a folder within this forum being updated so that we update the latest
 * date of the folder.
 */
-(void)handleFolderRefreshed:(NSNotification *)notification
{
    Response * response = (Response *)notification.object;
    if (response.errorCode == CCResponse_NoError)
    {
        Folder * folder = response.object;
        if (folder.parentFolder == _currentFolder.folder)
            [_forum getDateOfLatestMessage];
    }
}

/* Respond to a callback if the forum details have changed.
 */
-(void)handleForumChanged:(NSNotification *)notification
{
    Response * response = (Response *)notification.object;
    if (response.errorCode == CCResponse_NoError)
    {
        _forum = response.object;
        [self refreshForumView];
    }
}

/* We've retrieved the date of the latest message in this forum so display
 * it in the list.
 */
-(void)handleForumLatestDate:(NSNotification *)notification
{
    NSDate * latestDate = notification.object;
    if (latestDate != nil)
    {
        NSString * text = [NSString stringWithFormat:NSLocalizedString(@"Latest message in forum was posted on %@", nil), [latestDate friendlyDescription]];
        [forumLatestDate setStringValue:text];
        [forumLatestDate setHidden:NO];
    }
    else
        [forumLatestDate setHidden:YES];
}

/* Respond to a change in the list of moderators for the forum.
 */
-(void)handleModeratorsUpdated:(NSNotification *)notification
{
    [self refreshModerators];
}

/* Respond to a change in the list of moderators for the forum.
 */
-(void)handleMugshotUpdated:(NSNotification *)notification
{
    Response * response = (Response *)notification.object;
    if (response.errorCode == CCResponse_NoError)
    {
        Mugshot * updatedMugshot = response.object;
        for (ModeratorItem * item in arrayController.content)
            if ([item.name isEqualToString:updatedMugshot.username])
            {
                item.image = updatedMugshot.image;
                break;
            }
    }
}

/* Respond to a change in the forum join or resign status.
 */
-(void)handleForumJoinedOrResigned:(NSNotification *)notification
{
    Response * resp = notification.object;
    if (resp.errorCode == CCResponse_NoError)
    {
        Folder * folder = resp.object;
        if (folder == _currentFolder.folder)
            [self refreshResignButton];
    }
}

/* Respond to the user clicking on a moderator in the list.
 */
-(IBAction)imageClick:(id)sender
{
    CRImageView * imageView = (CRImageView *)sender;
    if (imageView.cell != nil && ((NSImageCell *)imageView.cell).representedObject != nil)
    {
        ModeratorCollectionViewItem * viewItem = ((NSImageCell *)imageView.cell).representedObject;
        ModeratorItem * item = viewItem.item;
    
        AppDelegate * app = (AppDelegate *)[NSApp delegate];
        [app setAddress:[NSString stringWithFormat:@"cixuser:%@", item.name]];
    }
}

/* Update the display of the forum from the _currentFolder
 * information.
 */
-(void)refreshForumView
{
    if (_forum != nil)
    {
        // Name, title and description from the directory
        forumName.stringValue = _forum.name;
        forumTitle.stringValue = _forum.title;
        
        NSString * desc = [SafeString(_forum.desc) stringByReplacingOccurrencesOfString:@"\n" withString:@"<br/>"];
        forumDescription.attributedStringValue = [NSAttributedString stringFromHTMLString:desc];
        
        [self refreshModerators];
        
        // Icon from the local service until such time that the API can
        // serve up custom icons.
        forumImage.image = [CategoryFolder iconForCategory:_forum.cat];
    }

    [self refreshResignButton];
}

/* Refresh the list of moderators.
 */
-(void)refreshModerators
{
    NSArray * moderators = [_forum moderators];
    NSMutableArray * viewList = [NSMutableArray array];
    for (NSString * moderator in moderators)
    {
        ModeratorItem * pm = [[ModeratorItem alloc] init];
        pm.name = moderator;
        pm.image = [Mugshot mugshotForUser:pm.name].image;
        [viewList addObject:pm];
    }
    [arrayController setContent:viewList];
    
    // Enable the Edit button if we're moderator
    [editButton setHidden:!_forum.isModerator];
}

/* Change the Resign button to a Rejoin button if the forum has already been
 * resigned, so we give the user the opportunity to rejoin it again.
 */
-(void)refreshResignButton
{
    BOOL isResigned = [_currentFolder.folder isResigned];
    [resignedText setHidden:!isResigned];
    resignedTextConstraint.constant = isResigned ? 17 : 0;
    
    if (![_currentFolder.folder canResign])
        [resignButton setHidden:YES];
    else if (isResigned)
    {
        [resignButton setHidden:NO];
        [resignButton setTitle:NSLocalizedString(@"Rejoin", nil)];
        [resignButton setAction:@selector(handleRejoinButton:)];
    }
    else
    {
        [resignButton setHidden:NO];
        [resignButton setTitle:NSLocalizedString(@"Resign", nil)];
        [resignButton setAction:@selector(handleResignButton:)];
    }
}

/* Manually refresh the forum details.
 */
-(IBAction)handleRefreshButton:(id)sender
{
    [_currentFolder refresh];
    [self refreshForumView];
}

/* Respond to the rejoin button to let the user rejoin a forum
 * from which they've resigned.
 */
-(IBAction)handleRejoinButton:(id)sender
{
    JoinForumController * joinForumController = [[JoinForumController alloc] initWithName:_forum.name];
    NSWindow * joinForumWindow = [joinForumController window];
    
    [joinForumWindow center];
    
    [NSApp runModalForWindow:joinForumWindow];
    [NSApp endSheet:joinForumWindow];
    [joinForumWindow orderOut: self];
}

/* Respond to the resign button to resign this forum.
 */
-(IBAction)handleResignButton:(id)sender
{
    [_currentFolder resign];
}

/* Respond to the delete button to delete this forum
 * locally.
 */
-(IBAction)handleDeleteButton:(id)sender
{
    [_currentFolder delete];
}

/* Handle the Participants button to show a panel listing all
 * participants of the forum.
 */
-(IBAction)handleParticipantsButton:(id)sender
{
    ParticipantsListController * partList = [[ParticipantsListController alloc] initWithForum:_forum];
    NSWindow * partListWindow = [partList window];
    
    [NSApp runModalForWindow:partListWindow];
    [NSApp endSheet:partListWindow];
    [partListWindow orderOut: self];
}

/* Respond to the Edit button to edit the forum details when
 * the authenticated user is the moderator.
 */
-(IBAction)handleEditButton:(id)sender
{
    MultiViewController * forumEditor = [[MultiViewController alloc] initWithConfig:@"ForumEditor.plist" andData:_forum];
    NSWindow * forumEditorWindow = [forumEditor window];
    
    [NSApp runModalForWindow:forumEditorWindow];
    [NSApp endSheet:forumEditorWindow];
    [forumEditorWindow orderOut:self];
}

/* Return whether the view can action the specified Action ID.
 */
-(BOOL)canAction:(ActionID)actionID
{
    if (actionID == ActionIDJoin)
        return [_currentFolder.folder isResigned];
    
    if (actionID == ActionIDManage)
        return _forum.isModerator;
    
    if (actionID == ActionIDParticipants)
        return YES;

    return actionID == ActionIDDelete;
}

/* Carry out the specified Action ID.
 */
-(void)action:(ActionID)actionID
{
    switch (actionID)
    {
        case ActionIDManage:
            [self handleEditButton:nil];
            break;
            
        case ActionIDParticipants:
            [self handleParticipantsButton:nil];
            break;
            
        case ActionIDJoin:
            [self handleRejoinButton:nil];
            break;

        case ActionIDDelete:
            [self handleDeleteButton:nil];
            break;
            
        default:
            break;
    }
}

/* Returns YES if the scheme is one we can handle.
 */
-(BOOL)handles:(NSString *)scheme
{
    return [scheme isEqualToString:@"cix"];
}

/* Return the address of this forum as a CIX link.
 */
-(NSString *)address
{
    return (_currentFolder != nil) ? [NSString stringWithFormat:@"cix:%@", _currentFolder.name] : nil;
}

/* Respond to keyboard actions at the view.
 */
-(BOOL)handleKeyDown:(unichar)keyChar withFlags:(NSUInteger)flags
{
    return [(AppDelegate *)[NSApp delegate] handleKeyDown:keyChar withFlags:flags];
}
@end
