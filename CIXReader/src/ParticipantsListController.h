//
//  ParticipantsListController.h
//  CIXReader
//
//  Created by Steve Palmer on 20/01/2015.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "DirForum.h"

@interface ParticipantsListController : NSWindowController {
    IBOutlet NSTableView * tableList;
    IBOutlet NSButton * viewProfileButton;
    IBOutlet NSButton * closeButton;
    IBOutlet NSView * loadingView;
    IBOutlet NSProgressIndicator * spinner;
    IBOutlet NSTextField * countText;
    
    DirForum * _forum;
    NSArray * _participants;
    BOOL _didInitialise;
}

// Accessors
-(id)initWithForum:(DirForum *)forum;

-(IBAction)handleViewProfile:(id)sender;
-(IBAction)handleClose:(id)sender;
@end
