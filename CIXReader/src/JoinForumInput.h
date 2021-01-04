//
//  JoinForumInput.h
//  CIXReader
//
//  Created by Steve Palmer on 16/10/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

@interface JoinForumInput : NSWindowController {
    IBOutlet NSButton * joinButton;
    IBOutlet NSTextField * inputField;
}

// Properties
@property NSString * name;

// Accessors
-(IBAction)handleJoinButton:(id)sender;
-(IBAction)handleCancelButton:(id)sender;
@end
