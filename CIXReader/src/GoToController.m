//
//  GoToController.m
//  CIXReader
//
//  Created by Steve Palmer on 24/10/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "GoToController.h"
#import "StringExtensions.h"
#import "CRNumericInputValidator.h"

@implementation GoToController

-(id)init
{
    return [super initWithWindowNibName:@"GoToController"];
}

-(void)awakeFromNib
{
    [self enableControls:nil];
    
    [inputField setStringValue:@""];
    
    CRNumericInputValidator * formatter = [[CRNumericInputValidator alloc] init];
    [inputField setFormatter:formatter];

    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(enableControls:) name: NSControlTextDidChangeNotification object:inputField];
}

/* Disable the Join button if the input field is blank.
 */
-(void)enableControls:(NSNotification *)aNotification
{
    NSString * string = [inputField stringValue];
    [okButton setEnabled:!IsEmpty(string)];
}

/* Respond to the Join button to close the sheet
 * and return a NSModalResponseOK response.
 */
-(IBAction)handleOKButton:(id)sender
{
    self.value = [inputField integerValue];
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
}

/* Respond to the Cancel button to close the sheet
 * and return a NSModalResponseCancel response.
 */
-(IBAction)handleCancelButton:(id)sender
{
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
}
@end
