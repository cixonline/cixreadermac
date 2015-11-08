//
//  EULAController.m
//  CIXReader
//
//  Created by Steve Palmer on 06/08/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "EULAController.h"

@implementation EULAController

-(id)init
{
    return [super initWithWindowNibName:@"EULA"];
}

/* Locate and display license RTF in the textview
 */
-(void)awakeFromNib
{
    NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
    NSString * pathToLicense = [thisBundle pathForResource:@"licence" ofType:@"rtf"];
    [eulaText readRTFDFromFile:pathToLicense];
    
    [appIcon setImage:[NSImage imageNamed:@"AppIcon"]];
}

/* Accept the EULA.
 */
-(IBAction)acceptEULA:(id)sender
{
    [NSApp stopModalWithCode:YES];
}

/* Reject the EULA.
 */
-(IBAction)rejectEULA:(id)sender
{
    [NSApp stopModalWithCode:NO];
}

/* Save the EULA to a file.
 */
-(IBAction)saveEULA:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setPrompt:NSLocalizedString(@"Save", @"Save")];
    [savePanel setNameFieldStringValue:@"CIXReader EULA"];
    [savePanel setAllowedFileTypes:@[ @"rtf" ]];
    
    if (NSFileHandlingPanelOKButton == [savePanel runModal])
    {
        NSRange textRange = NSMakeRange(0, [[eulaText string] length]);
        [[eulaText RTFFromRange:textRange] writeToFile:[[savePanel URL] path] atomically:YES];
    }
}
@end
