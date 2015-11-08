//
//  ModeratorForumEditor.m
//  CIXReader
//
//  Created by Steve Palmer on 13/10/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "ModeratorForumEditor.h"
#import "CIX.h"

@implementation ModeratorForumEditor

-(id)initWithObject:(id)forum
{
    if ((self = [super initWithNibName:@"ModeratorForumEditor" bundle:nil]) != nil)
        _forum = forum;
    
    return self;
}

/* Fill out the table with the existing list of moderators.
 */
-(void)awakeFromNib
{
    if (!_didInitialise)
    {
        [self setUserList:_forum.moderators];
        [self setAddList:_forum.addedModerators];
        [self setRemoveList:_forum.removedModerators];
        
        NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(handleModeratorsUpdated:) name:MAModeratorsUpdated object:nil];
        
        [super awakeFromNib];
        _didInitialise = YES;
    }
}

-(void)handleModeratorsUpdated:(NSNotification *)notification
{
    [self setUserList:_forum.moderators];
    [self setAddList:_forum.addedModerators];
    [self setRemoveList:_forum.removedModerators];
    [super updateList];
}

/* Close the view and save any changes.
 */
-(BOOL)closeView:(BOOL)response
{
    if (response)
    {
        [_forum removeModerators:_toRemove];
        [_forum addModerators:_toAdd];
        
        [_forum update];
    }
    
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:MAModeratorsUpdated object:nil];

    return [super closeView:response];
}
@end
