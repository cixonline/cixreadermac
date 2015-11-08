//
//  ParticipantForumEditor.h
//  CIXReader
//
//  Created by Steve Palmer on 18/01/2015.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "UserForumEditor.h"

@interface ParticipantForumEditor : UserForumEditor {
    BOOL _didInitialise;
    DirForum * _forum;
}

// Accessors
-(id)initWithObject:(id)forum;
@end
