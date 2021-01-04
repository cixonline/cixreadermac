//
//  GeneralForumEditor.h
//  CIXReader
//
//  Created by Steve Palmer on 06/10/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "CIX.h"
#import "MultiViewController.h"

@interface GeneralForumEditor : NSViewController<MultiViewInterface>{
    IBOutlet NSTextField * forumName;
    IBOutlet NSTextField * forumTitle;
    IBOutlet NSTextView * forumDescription;
    IBOutlet NSPopUpButton * forumType;
    IBOutlet NSPopUpButton * forumCategory;
    IBOutlet NSPopUpButton * forumSubCategory;
    
    DirForum * _forum;
    BOOL _didInitialise;
}

// Accessors
-(id)initWithObject:(id)forum;
-(IBAction)handleForumTypeChange:(id)sender;
-(IBAction)handleSaveButton:(id)sender;
-(IBAction)handleCancelButton:(id)sender;
@end
