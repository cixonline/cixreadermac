//
//  ViewBaseView.h
//  CIXReader
//
//  Created by Steve Palmer on 28/08/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "FolderBase.h"
#import "Address.h"
#import "FoldersTree.h"

// Various action IDs that each view can
// implement.
typedef enum
{
    ActionIDDelete,
    ActionIDManage,
    ActionIDReply,
    ActionIDReplyByMail,
    ActionIDReplyWithQuote,
    ActionIDShowProfile,
    ActionIDJoin,
    ActionIDGoto,
    ActionIDGotoPreviousRoot,
    ActionIDGotoNextRoot,
    ActionIDGotoOriginal,
    ActionIDWithdraw,
    ActionIDPrint,
    ActionIDMarkRead,
    ActionIDMarkStar,
    ActionIDMarkReadLock,
    ActionIDMarkPriority,
    ActionIDMarkIgnore,
    ActionIDMarkThreadRead,
    ActionIDNewMessage,
    ActionIDEditMessage,
    ActionIDBiggerText,
    ActionIDSmallerText,
    ActionIDScrollMessage,
    ActionIDCopyLink,
    ActionIDParticipants,
    ActionIDExpandCollapseThread,
    ActionIDBlock
} ActionID;

#define Sort_Date           1
#define Sort_Author         2
#define Sort_Subject        3
#define Sort_Title          4
#define Sort_Name           5
#define Sort_SubCategory    6
#define Sort_Popularity     7

#define Sort_Ascending      100
#define Sort_Descending     101

@interface ViewBaseView : NSViewController {
    NSString * _sortOrderPreference;
    NSString * _sortDirectionPreference;

    NSInteger _currentSortOrder;
    BOOL _sortAscending;
}

// Accessors
-(void)initSorting:(NSInteger)order ascending:(BOOL)flag;
-(BOOL)viewFromFolder:(FolderBase *)folder withAddress:(Address *)address options:(FolderOptions)options;
-(BOOL)validateMenuItem:(NSMenuItem *)menuItem;
-(BOOL)canAction:(ActionID)actionID;
-(NSString *)titleForAction:(ActionID)actionID;
-(NSString *)imageForAction:(ActionID)actionID;
-(void)action:(ActionID)actionID;
-(BOOL)handles:(NSString *)scheme;
-(NSString *)address;
-(NSMenu *)sortMenu;
-(void)sortConversations:(BOOL)update;
-(void)filterViewByString:(NSString *)string;
-(NSString *)title;

// Interface Builder actions
-(IBAction)sortOrderChanged:(id)sender;
-(IBAction)sortDirectionChanged:(id)sender;
@end
