//
//  ModeratorForumEditor.h
//  CIXReader
//
//  Created by Steve Palmer on 13/10/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "UserForumEditor.h"

@interface ModeratorForumEditor : UserForumEditor {
    BOOL _didInitialise;
    DirForum * _forum;
}

// Accessors
-(id)initWithObject:(id)forum;
@end
