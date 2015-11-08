//
//  FoldersTree.h
//  CIXReader
//
//  Created by Steve Palmer on 20/08/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "CRFolderView.h"
#import "FolderBase.h"
#import "SearchFolder.h"
#import "ForumGroup.h"
#import "MailGroup.h"
#import "Address.h"

typedef enum
{
    FolderOptionsNextUnread = 1,
    FolderOptionsPriority = 2,
    FolderOptionsClearFilter = 4,
    FolderOptionsRoot = 8,
    FolderOptionsReset = 16
} FolderOptions;

@interface FoldersTree : NSView {
    IBOutlet CRFolderView * folderView;
    
	NSFont * _cellFont;
    
    BOOL _showAllTopics;
    BOOL _fireSelectionChangedEvent;
    BOOL _needReload;
    BOOL _isInDrag;
    BOOL _didInitialise;
    
    FolderBase * _root;
    FolderBase * _directoryTree;
    FolderBase * _homePage;
    MailGroup * _messagesTree;
    ForumGroup * _forumsTree;
    SearchFolder * _searchFolder;
    
    Address * _lastAddress;
}

// Accessors
-(void)initialiseFoldersTree;
-(void)update;
-(void)activate:(BOOL)isActive;
-(FolderBase *)selection;
-(void)nextUnread:(FolderOptions)options;
-(BOOL)selectAddress:(Address *)address;
-(IBAction)handleMarkRead:(id)sender;
-(SearchFolder *)searchFolder;
-(void)selectSearchFolder;
@end
