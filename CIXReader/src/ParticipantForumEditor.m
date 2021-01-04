//
//  ParticipantForumEditor.m
//  CIXReader
//
//  Created by Steve Palmer on 18/01/2015.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "ParticipantForumEditor.h"
#import "CIX.h"

@implementation ParticipantForumEditor

-(id)initWithObject:(id)forum
{
    if ((self = [super initWithNibName:@"ParticipantForumEditor" bundle:nil]) != nil)
        _forum = forum;
    
    return self;
}

/* Fill out the table with the existing list of moderators.
 */
-(void)awakeFromNib
{
    if (!_didInitialise)
    {
        [self setUserList:_forum.participants];
        [self setAddList:_forum.addedParticipants];
        [self setRemoveList:_forum.removedParticipants];

        NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(handleParticipantsUpdated:) name:MAParticipantsUpdated object:nil];
        
        [super awakeFromNib];
        _didInitialise = YES;
    }
}

-(void)handleParticipantsUpdated:(NSNotification *)notification
{
    [self setUserList:_forum.participants];
    [self setAddList:_forum.addedParticipants];
    [self setRemoveList:_forum.removedParticipants];
    [super updateList];
}

/* Close the view and save any changes.
 */
-(BOOL)closeView:(BOOL)response
{
    if (response)
    {
        [_forum removeParticipants:_toRemove];
        [_forum addParticipants:_toAdd];
        
        [_forum update];
    }
    
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:MAParticipantsUpdated object:nil];

    return [super closeView:response];
}
@end
