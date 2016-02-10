//
//  LoginController.m
//  CIXReader
//
//  Created by Steve Palmer on 06/08/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "LoginController.h"
#import "StringExtensions.h"
#import "Preferences.h"
#import "CIX.h"

@interface LoginController (Private)
-(void)enableControls:(NSNotification *)aNotification;
@end

static NSString * recoverPasswordLink = @"https://forums.cixonline.com/recoverpassword.aspx";
static NSString * signUpToCIXLink = @"https://forums.cix.co.uk/signUp.aspx?p=cixreader";

@implementation LoginController

-(id)init
{
    if ((self = [super initWithWindowNibName:@"Login"]) != nil)
    {
        _username = @"";
        _password = @"";
    }
    return self;
}

/* Hook up notifications for text changes.
 */
-(void)windowDidLoad
{
    [usernameField setStringValue:_username];
    [passwordField setStringValue:_password];
    
    if (![_username isBlank])
        [[self window] makeFirstResponder:passwordField];
    
    [self enableControls:nil];
    
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(enableControls:) name: NSControlTextDidChangeNotification object:usernameField];
    [nc addObserver:self selector:@selector(enableControls:) name: NSControlTextDidChangeNotification object:passwordField];
}

/* Disable the Login button if the username or password are blank.
 */
-(void)enableControls:(NSNotification *)aNotification
{
    NSString * theUsername = [usernameField stringValue];
    NSString * thePassword = [passwordField stringValue];
    [loginButton setEnabled:![theUsername isBlank] && ![thePassword isBlank]];
}

/* Handle the Sign up button to open the CIX signup website.
 */
-(IBAction)handleSignUpToCIX:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:signUpToCIXLink]];
}

/* Respond to the login button. Both username and password
 * should be non-empty at this point.
 */
-(IBAction)handleLoginButton:(id)sender
{
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(handleAuthentication:) name: MAUserAuthenticationCompleted object:nil];

    _username = [usernameField stringValue];
    _password = [passwordField stringValue];
    
    // Disable the buttons while we validate
    [loginButton setEnabled:NO];
    [usernameField setEnabled:NO];
    [passwordField setEnabled:NO];
    
    [CIX authenticate:_username withPassword:_password];
}

-(IBAction)handleForgotLink:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:recoverPasswordLink]];
}

/* Handle callback when the service has completed authentication of
 * the specified user account.
 */
-(void)handleAuthentication:(NSNotification *)notification
{
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:MAUserAuthenticationCompleted object:nil];
    
    NSString * accountType = [notification object];
    if (accountType != nil && ![accountType isEqualToString:@"activate"])
    {
        Preferences * prefs = [Preferences standardPreferences];
        [prefs setLastUser:_username];
        
        [NSApp stopModalWithCode:YES];
        return;
    }
    
    // Not authenticated, so re-enable the controls and tell the user
    // what happened.
    NSString * error;
    if ([accountType isEqualToString:@"activate"])
        error = NSLocalizedString(@"Your account has not yet been activated.", nil);
    else
        error = NSLocalizedString(@"Your username or password were entered incorrectly", nil);
    runOKAlertPanel(NSLocalizedString(@"Authentication Error", nil), error);
    
    [loginButton setEnabled:YES];
    [usernameField setEnabled:YES];
    [passwordField setEnabled:YES];
}

/* Displays an alert panel with just an OK button.
 */
void runOKAlertPanel(NSString * titleString, NSString * bodyText, ...)
{
    NSString * fullBodyText;
    va_list arguments;
    
    va_start(arguments, bodyText);
    fullBodyText = [[NSString alloc] initWithFormat:bodyText arguments:arguments];
    // Security: arguments may contain formatting characters, so don't use fullBodyText as format string.
    NSRunAlertPanel(titleString, @"%@", NSLocalizedString(@"OK", nil), nil, nil, fullBodyText);
    va_end(arguments);
}

/* Respond to the cancel button.
 */
-(IBAction)handleCancelButton:(id)sender
{
    [NSApp stopModalWithCode:NO];
}
@end
