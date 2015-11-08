//
//  EULAController.h
//  CIXReader
//
//  Created by Steve Palmer on 06/08/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

@interface EULAController : NSWindowController
{
    IBOutlet NSTextView * eulaText;
    IBOutlet NSButton * acceptButton;
    IBOutlet NSButton * rejectButton;
    IBOutlet NSButton * saveButton;
    IBOutlet NSImageView * appIcon;
}

-(IBAction)acceptEULA:(id)sender;
-(IBAction)rejectEULA:(id)sender;
-(IBAction)saveEULA:(id)sender;
@end
