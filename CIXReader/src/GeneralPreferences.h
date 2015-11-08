//
//  GeneralPreferences.h
//  CIXReader
//
//  Created by Steve Palmer on 21/09/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

@interface GeneralPreferences : NSViewController {
    IBOutlet NSButton * enableLogFiles;
    IBOutlet NSButton * archiveLogFiles;
    IBOutlet NSButton * openLogFile;
    IBOutlet NSButton * startOffline;
    IBOutlet NSButton * startAtHomePage;
    IBOutlet NSMatrix * appBadgeMatrix;
    IBOutlet NSPopUpButton * cleanUpCacheList;
    
    BOOL _didInitialise;
}

// Accessors
-(id)initWithObject:(id)data;
-(IBAction)changeEnableLogFiles:(id)sender;
-(IBAction)changeArchiveLogFiles:(id)sender;
-(IBAction)handleOpenLogFile:(id)sender;
-(IBAction)changeStartOffline:(id)sender;
-(IBAction)changeStartAtHomePage:(id)sender;
-(IBAction)changeAppBadgeMode:(id)sender;
-(IBAction)cleanUpCacheChanged:(id)sender;
@end
