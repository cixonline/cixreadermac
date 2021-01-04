//
//  JoinForumInput.m
//  CIXReader
//
//  Created by Steve Palmer on 16/10/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "JoinForumInput.h"
#import "StringExtensions.h"

@implementation JoinForumInput

-(id)init
{
    return [super initWithWindowNibName:@"JoinForumInput"];
}

-(void)awakeFromNib
{
    [self enableControls:nil];
    
    [inputField setStringValue:@""];
    
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(enableControls:) name: NSControlTextDidChangeNotification object:inputField];
}

/* Disable the Join button if the input field is blank.
 */
-(void)enableControls:(NSNotification *)aNotification
{
    NSString * string = [inputField stringValue];
    [joinButton setEnabled:!IsEmpty(string)];
}

/* Respond to the Join button to close the sheet
 * and return a NSModalResponseOK response.
 */
-(IBAction)handleJoinButton:(id)sender
{
    self.name = [[inputField stringValue] trim];
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
