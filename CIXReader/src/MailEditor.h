//
//  MailEditor.h
//  CIXReader
//
//  Created by Steve Palmer on 11/09/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "Signatures.h"
#import "CIX.h"

@interface MailEditor : NSWindowController<NSToolbarDelegate, NSWindowDelegate> {
    IBOutlet NSWindow * messageWindow;
    IBOutlet NSTextView * textView;
    IBOutlet NSTextField * recipient;
    IBOutlet NSTextField * subject;
    IBOutlet NSPopUpButton * signaturesList;
    
    NSString * _currentSignature;
    NSString * _defaultRecipient;
    Message * _messageToUse;
    MailMessage * _currentMessage;
    Conversation * _currentConversation;
}

// Init functions
-(id)initWithConversation:(Conversation *)conversation;
-(id)initWithMessage:(Message *)message;
-(id)initWithRecipient:(NSString *)recipient;

// Action messages
-(IBAction)sendMessage:(id)sender;
-(IBAction)signatureSelected:(id)sender;
@end
