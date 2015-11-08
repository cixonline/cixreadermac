//
//  ProfileController.h
//  CIXReader
//
//  Created by Steve Palmer on 25/09/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "CRRoundImageView.h"
#import "CIX.h"

@interface ProfileController : NSWindowController {
    IBOutlet CRRoundImageView * mugshotImage;
    IBOutlet NSTextField * username;
    IBOutlet NSTextField * fullname;
    IBOutlet NSTextField * location;
    IBOutlet NSTextField * emailAddress;
    IBOutlet NSTextView * about;
    IBOutlet NSTextField * firstOn;
    IBOutlet NSTextField * lastOn;
    IBOutlet NSTextField * lastPost;
    IBOutlet NSButton * mailButton;
    IBOutlet NSButton * locationButton;
    
    Profile * _currentProfile;
}

// Accessors
-(id)initWithProfile:(Profile *)profile;
-(IBAction)launchLocation:(id)sender;
-(IBAction)launchMail:(id)sender;
@end
