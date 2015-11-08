//
//  SignaturePreferences.h
//  CIXReader
//
//  Created by Steve Palmer on 04/11/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

@interface SignaturePreferences : NSViewController {
    IBOutlet NSTableView * signaturesList;
    IBOutlet NSButton * newSignatureButton;
    IBOutlet NSButton * editSignatureButton;
    IBOutlet NSButton * deleteSignatureButton;
    IBOutlet NSButton * saveSignatureButton;
    IBOutlet NSButton * cancelSignatureButton;
    IBOutlet NSTextView * signatureText;
    IBOutlet NSTextField * signatureTitle;
    IBOutlet NSWindow * signatureEditor;
    IBOutlet NSPopUpButton * defaultSignature;

    NSArray * _arrayOfSignatures;
    NSString * _signatureBeingEdited;
    BOOL _didInitialise;
}

// Accessors
-(id)initWithObject:(id)data;
-(IBAction)newSignature:(id)sender;
-(IBAction)editSignature:(id)sender;
-(IBAction)deleteSignature:(id)sender;
-(IBAction)saveSignature:(id)sender;
-(IBAction)cancelSignature:(id)sender;
-(IBAction)selectDefaultSignature:(id)sender;
@end
