//
//  MessageEditor.h
//  CIXReader
//
//  Created by Steve Palmer on 04/11/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "Signatures.h"
#import "CRTextView.h"
#import "CIX.h"

@interface MessageEditor : NSWindowController<NSToolbarDelegate, NSWindowDelegate> {
    IBOutlet NSWindow * messageWindow;
    IBOutlet CRTextView * textView;
    IBOutlet NSPopUpButton * signaturesList;
    
    Folder * _folder;
    Message * _originalMessage;
    NSString * _currentSignature;
    BOOL _addSignature;
}

// Accessors
-(id)initWithMessage:(Message *)message addSignature:(BOOL)addSignature;
-(id)initWithFolder:(Folder *)folder;

-(IBAction)sendMessage:(id)sender;
-(IBAction)signatureSelected:(id)sender;
-(IBAction)handleInsertImage:(id)sender;
@end
