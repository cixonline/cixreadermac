//
//  LoginController.h
//  CIXReader
//
//  Created by Steve Palmer on 06/08/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "CRLinkedTextField.h"

@interface LoginController : NSWindowController {
    IBOutlet NSButton * loginButton;
    IBOutlet NSButton * cancelButton;
    IBOutlet NSTextField * usernameField;
    IBOutlet NSSecureTextField * passwordField;
    IBOutlet NSButton * signUpToCIX;
    IBOutlet CRLinkedTextField * forgotLabel;
}

// Accessors
-(IBAction)handleSignUpToCIX:(id)sender;
-(IBAction)handleLoginButton:(id)sender;
-(IBAction)handleCancelButton:(id)sender;
-(IBAction)handleForgotLink:(id)sender;

// Properties
@property NSString * username;
@property NSString * password;
@end
