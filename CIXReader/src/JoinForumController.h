//
//  JoinForumController.h
//  CIXReader
//
//  Created by Steve Palmer on 09/10/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "CIX.h"

@interface JoinForumController : NSWindowController {
    IBOutlet NSImageView * forumImage;
    IBOutlet NSTextField * forumName;
    IBOutlet NSTextField * forumTitle;
    IBOutlet NSTextField * forumDescription;
    IBOutlet NSTextField * statusField;
    IBOutlet NSButton * joinButton;
    IBOutlet NSButton * cancelButton;
    
    NSString * _forumName;
    DirForum * _forum;
}

// Accessors
-(id)initWithName:(NSString *)name;
-(IBAction)handleJoinButton:(id)sender;
-(IBAction)handleCancelButton:(id)sender;
@end
