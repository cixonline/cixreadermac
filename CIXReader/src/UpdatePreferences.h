//
//  UpdatePreferences.h
//  CIXReader
//
//  Created by Steve Palmer on 21/09/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

@interface UpdatePreferences : NSViewController {
    IBOutlet NSButton * checkForUpdates;
    IBOutlet NSButton * useBetaReleases;
    
    BOOL _didInitialise;
}

// Accessors
-(id)initWithObject:(id)data;
-(IBAction)changeCheckForUpdates:(id)sender;
-(IBAction)changeUseBetaReleases:(id)sender;
@end
