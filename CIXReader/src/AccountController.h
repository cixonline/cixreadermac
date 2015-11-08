//
//  AccountController.h
//  CIXReader
//
//  Created by Steve Palmer on 26/08/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "CRRoundImageView.h"

@interface AccountController : NSWindowController {
    IBOutlet NSButton * saveButton;
    IBOutlet NSButton * upgradeButton;
    IBOutlet NSButton * editButton;
    IBOutlet NSTextField * accountName;
    IBOutlet NSTextField * accountType;
    IBOutlet NSTextField * lastOnDate;
    IBOutlet NSTextField * fullName;
    IBOutlet NSTextField * eMailAddress;
    IBOutlet NSTextField * location;
    IBOutlet NSButton * notifyPM;
    IBOutlet NSButton * notifyTagged;
    IBOutlet NSPopUpButton * sexList;
    IBOutlet NSTextView * aboutText;
    IBOutlet CRRoundImageView * mugshotImage;
    
    NSDateFormatter * _dateFormatter;
    BOOL _isImageModified;
    BOOL _isInitialised;
    BOOL _isEditing;
}

// Accessors
-(IBAction)handleCloseButton:(id)sender;
-(IBAction)handleEditButton:(id)sender;
@end
