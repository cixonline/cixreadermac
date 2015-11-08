//
//  DirectoryView.h
//  CIXReader
//
//  Created by Steve Palmer on 25/08/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "ViewBaseView.h"
#import "CategoryFolder.h"

@interface DirectoryView : ViewBaseView <NSTableViewDelegate, NSTableViewDataSource> {
    IBOutlet NSTableView * forumsList;
    IBOutlet NSMenu * sortMenu;
    
    CategoryFolder * _currentCategory;
    NSMutableArray * _currentList;
    NSImage * _lockImage;
    NSFont * _cellFont;
    BOOL _didInitialise;
}

// Accessors
-(IBAction)handleJoinButton:(id)sender;
@end
