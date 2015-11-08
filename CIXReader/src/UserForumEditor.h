//
//  UserForumEditor.h
//  CIXReader
//
//  Created by Steve Palmer on 19/01/2015.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "DirForum.h"
#import "MultiViewController.h"

@interface UserForumEditor : NSViewController<MultiViewInterface> {
    IBOutlet NSTableView * tableView;
    IBOutlet NSButton * addButton;
    IBOutlet NSButton * removeButton;
    IBOutlet NSView * loadingView;
    IBOutlet NSProgressIndicator * spinner;
    
    IBOutlet NSWindow * addPanel;
    IBOutlet NSButton * addPanelAddButton;
    IBOutlet NSButton * addPanelCancelButton;
    IBOutlet NSTextField * addTextField;
    
    NSArray * _users;
    NSMutableArray * _toRemove;
    NSMutableArray * _toAdd;
    NSArray * _list;
    BOOL _didInitialise2;
    
    NSDictionary * greyAttr;
}

// Accessors
-(void)setUserList:(NSArray *)list;
-(void)setAddList:(NSArray *)list;
-(void)setRemoveList:(NSArray *)list;
-(void)updateList;

-(BOOL)closeView:(BOOL)response;

-(IBAction)handleAddButton:(id)sender;
-(IBAction)handleRemoveButton:(id)sender;
-(IBAction)handleSaveButton:(id)sender;
-(IBAction)handleCancelButton:(id)sender;

-(IBAction)handleAddPanelAddButton:(id)sender;
-(IBAction)handleAddPanelCancelButton:(id)sender;
@end
