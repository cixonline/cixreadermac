//
//  ViewingPreferences.h
//  CIXReader
//
//  Created by Steve Palmer on 21/09/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "StyleController.h"

@interface ViewingPreferences : NSViewController {
    IBOutlet NSTextField * articleFontSample;
    IBOutlet NSTextField * folderFontSample;
    IBOutlet NSTextField * messageFontSample;
    IBOutlet NSButton * articleFontSelectButton;
    IBOutlet NSButton * folderFontSelectButton;
    IBOutlet NSButton * messageFontSelectButton;
    IBOutlet NSPopUpButton * stylesList;
    
    StyleController * _stylesController;
    BOOL _didInitialise;
    BOOL _skipInit;
}

// Accessors
-(id)initWithObject:(id)data;
-(IBAction)selectArticleFont:(id)sender;
-(IBAction)selectFolderFont:(id)sender;
-(IBAction)selectMessageFont:(id)sender;
-(IBAction)stylesListChanged:(id)sender;
@end
