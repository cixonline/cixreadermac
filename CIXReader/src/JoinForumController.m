//
//  JoinForumController.m
//  CIXReader
//
//  Created by Steve Palmer on 09/10/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "JoinForumController.h"
#import "CategoryFolder.h"
#import "StringExtensions.h"

@implementation JoinForumController

-(id)initWithName:(NSString *)name
{
    if ((self = [super initWithWindowNibName:@"JoinForum"]) != nil)
        _forumName = name;
    return self;
}

/* When displaying the Join Forum window, we only have the forum
 * name to start with, so make a request for the forum details and
 * populate those when we get them.
 */
-(void)awakeFromNib
{
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(refreshForumDetails:) name:MAForumChanged object:nil];
    [nc addObserver:self selector:@selector(handleForumJoinResponse:) name:MAForumJoined object:nil];
    [nc addObserver:self selector:@selector(handleForumJoinResponse:) name:MAForumRequestedAdmission object:nil];
    
    _forum = [CIX.directoryCollection forumByName:_forumName];
    if (_forum != nil && !IsEmpty(_forum.desc))
        [self refreshForum:_forum];
    else
    {
        if (_forum != nil)
            [forumTitle setStringValue:_forum.title];
        [forumName setStringValue:_forumName];
        [forumImage setImage:[CategoryFolder iconForCategory:@"CIX"]]; // Placeholder icon
        [CIX.directoryCollection refreshForum:_forumName];
    }
}

/* Callback on completion of a refreshForum on the forum name. The
 * returned object is a DirForum with all fields filled out.
 */
-(void)refreshForumDetails:(NSNotification *)notification
{
    Response * response = (Response *)notification.object;
    if (response.errorCode == CCResponse_NoError)
    {
        _forum = (DirForum *)response.object;
        [self refreshForum:_forum];
    }
    else if (response.errorCode == CCResponse_NoSuchForum)
    {
        [statusField setTextColor:[NSColor controlTextColor]];
        [statusField setStringValue:NSLocalizedString(@"This forum does not exist in the directory. Check the spelling of the name.", nil)];
        
        [forumTitle setHidden:YES];
        [forumDescription setHidden:YES];
        
        // Repurpose the Join button to just close the dialog.
        [joinButton setTitle:NSLocalizedString(@"Close", nil)];
        [joinButton setEnabled:YES];
        [joinButton setAction:@selector(handleCancelButton:)];
        [cancelButton setHidden:YES];
    }
}

/* Update the window with the data in the DirForum. Note that some
 * fields may be blank - this is normal.
 */
-(void)refreshForum:(DirForum *)forum
{
    if (forum != nil)
    {
        forumName.stringValue = forum.name;
        forumTitle.stringValue = forum.title;
        forumImage.image = [CategoryFolder iconForCategory:forum.cat];
        forumDescription.attributedStringValue = [NSAttributedString stringFromHTMLString:SafeString(_forum.desc)];
        
        if (forum.isClosed)
        {
            [statusField setTextColor:[NSColor controlTextColor]];
            [statusField setStringValue:NSLocalizedString(@"This forum is closed. To join the forum, you need to contact the moderators to request admittance", nil)];
            
            // Repurpose the Join button to contact the moderators.
            [joinButton setTitle:NSLocalizedString(@"Request Admittance", nil)];
            [joinButton setEnabled:YES];
            [joinButton setAction:@selector(handleContactModerators:)];
        }
    }
}

/* Callback from the [DirForum join] request. This is called whether or not the
 * join request succeeds.
 */
-(void)handleForumJoinResponse:(NSNotification *)notification
{
    Response * response = [notification object];
    switch (response.errorCode)
    {
        case CCResponse_NoError:
            // Trigger a refresh of the user's subscriptions to pull down the new forum
            // and add it to the offline database.
            
        case CCResponse_Offline:
            [NSApp stopModalWithCode:YES];
            break;

        // At the moment, the API doesn't give us much granularity over Join errors so the
        // error message is a catch-all. Once we have more granularity, we can handle
        // other CCResponse errors.
        default:
            [statusField setTextColor:[NSColor controlTextColor]];
            [statusField setStringValue:NSLocalizedString(@"Sorry, you cannot join this forum. The forum may be " \
                                                           "closed or you may have reached the limit of the " \
                                                           "number of forums you can join with your account.", nil)];

            // Repurpose the Join button to just close the dialog.
            [joinButton setTitle:NSLocalizedString(@"Close", nil)];
            [joinButton setEnabled:YES];
            [joinButton setAction:@selector(handleCancelButton:)];
            [cancelButton setHidden:YES];
            break;
    }
}

/* For closed forums, we need to contact the forum moderators. To do this,
 * we need to issue a call to the API to send out a request admittance
 * notification.
 */
-(IBAction)handleContactModerators:(id)sender
{
    [statusField setStringValue:NSLocalizedString(@"Please wait...", nil)];
    [joinButton setEnabled:NO];
    [_forum requestAdmission];
}

/* Respond to the user clicking the Join button. We trigger an
 * asynchronous call to [DirForum join] and wait for the response before
 * dismissing the window.
 */
-(IBAction)handleJoinButton:(id)sender
{
    [statusField setStringValue:NSLocalizedString(@"Joining forum...", nil)];
    [joinButton setEnabled:NO];
    [_forum join];
}

/* Respond to the Cancel button to dismiss the window and do nothing.
 */
-(IBAction)handleCancelButton:(id)sender
{
    [NSApp stopModalWithCode:NO];
}
@end
