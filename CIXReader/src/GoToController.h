//
//  GoToInput.h
//  CIXReader
//
//  Created by Steve Palmer on 24/10/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

@interface GoToController : NSWindowController {
    IBOutlet NSButton * okButton;
    IBOutlet NSTextField * inputField;
}

// Properties
@property NSInteger value;

// Accessors
-(IBAction)handleOKButton:(id)sender;
-(IBAction)handleCancelButton:(id)sender;
@end
