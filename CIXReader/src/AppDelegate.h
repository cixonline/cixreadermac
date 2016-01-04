//
//  AppDelegate.h
//  CIXReader
//
//  Created by Steve Palmer on 30/07/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "MultiViewController.h"
#import "AccountController.h"
#import "JoinForumInput.h"
#import "Constants.h"
#import "FoldersTree.h"
#import "Address.h"
#import "ViewBaseView.h"
#import "BackTrackArray.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSSplitViewDelegate, NSWindowDelegate, NSToolbarDelegate, NSMenuDelegate> {
@private
    IBOutlet FoldersTree * foldersTree;
    IBOutlet NSWindow * mainWindow;
    IBOutlet NSMenuItem * offlineMenuItem;
    IBOutlet NSView * contentView;
    IBOutlet NSTextField * statusText;
	IBOutlet NSView * statusBar;
    IBOutlet NSLayoutConstraint * topConstraint;
    IBOutlet NSProgressIndicator * spinner;
    IBOutlet NSMenuItem * sortMenu;
    IBOutlet NSSearchField * searchFieldOutlet;
    IBOutlet NSSplitView * splitter;

    MultiViewController * _preferenceController;
    JoinForumInput * _joinForumInputController;
    
    NSDictionary * _allViews;
    NSString * _userTitleString;
    NSString * _launchAddress;
    NSString * _persistedStatusText;
    NSDate * _lastSyncTime;
    ViewBaseView * _currentView;
    AppView _currentAppView;
    BackTrackArray * _backtrackArray;
    int _progressCount;
    int _statusBarHeight;
    BOOL _isStatusBarVisible;
    BOOL _isBacktracking;
    BOOL _allowOnlineStateChange;
}

// Properties
@property(retain) IBOutlet NSMenu * folderMenu;
@property(retain) IBOutlet NSMenu * articleMenu;

// Action handlers
-(IBAction)showPreferencesPanel:(id)sender;
-(IBAction)showAccountPanel:(id)sender;
-(IBAction)handleSignOut:(id)sender;
-(IBAction)toggleOffline:(id)sender;
-(IBAction)handleRecentTopics:(id)sender;
-(IBAction)handleAllTopics:(id)sender;
-(IBAction)showHideStatusBar:(id)sender;
-(IBAction)handleNewMail:(id)sender;
-(IBAction)handleReply:(id)sender;
-(IBAction)handleReplyByMail:(id)sender;
-(IBAction)handleNewMessage:(id)sender;
-(IBAction)handleEditMessage:(id)sender;
-(IBAction)handleComment:(id)sender;
-(IBAction)handleFolderResign:(id)sender;
-(IBAction)handleForumManage:(id)sender;
-(IBAction)handleForumParticipants:(id)sender;
-(IBAction)handleMarkAllRead:(id)sender;
-(IBAction)handleJoinForum:(id)sender;
-(IBAction)handleGoTo:(id)sender;
-(IBAction)handleGoToOriginal:(id)sender;
-(IBAction)handleGoToNextRoot:(id)sender;
-(IBAction)handleGoToPreviousRoot:(id)sender;
-(IBAction)handleWithdraw:(id)sender;
-(IBAction)handleBlock:(id)sender;
-(IBAction)handleShowProfile:(id)sender;
-(IBAction)handleBiggerText:(id)sender;
-(IBAction)handleSmallerText:(id)sender;
-(IBAction)showHelpSupport:(id)sender;
-(IBAction)handleCheckForUpdates:(id)sender;
-(IBAction)handleMarkRead:(id)sender;
-(IBAction)handleMarkReadLock:(id)sender;
-(IBAction)handleMarkStar:(id)sender;
-(IBAction)handleMarkPriority:(id)sender;
-(IBAction)handleMarkIgnore:(id)sender;
-(IBAction)handleMarkReadThread:(id)sender;
-(IBAction)handleMarkReadThreadThenRoot:(id)sender;
-(IBAction)handleExpandCollapseThread:(id)sender;
-(IBAction)handleNextUnread:(id)sender;
-(IBAction)handleNextUnreadPriority:(id)sender;
-(IBAction)handleScrollThenNextUnread:(id)sender;
-(IBAction)goForward:(id)sender;
-(IBAction)goBack:(id)sender;
-(IBAction)delete:(id)sender;
-(IBAction)handleShowPlaintext:(id)sender;
-(IBAction)handleShowInlineImages:(id)sender;
-(IBAction)handleShowIgnored:(id)sender;
-(IBAction)handleRefresh:(id)sender;
-(IBAction)showAcknowledgements:(id)sender;
-(IBAction)quoteOriginal:(id)sender;
-(IBAction)handleCopyLink:(id)sender;
-(IBAction)handleViewChangeLog:(id)sender;
-(IBAction)handleGroupByConv:(id)sender;
-(IBAction)handleCollapseConv:(id)sender;

// Public methods
-(NSLayoutManager *)layoutManager;
-(void)setLaunchAddress:(NSString *)linkPath;
-(Folder *)currentFolder;
-(Message *)currentMessage;
-(BOOL)selectViewForFolder:(FolderBase *)folder withAddress:(Address *)address options:(FolderOptions)options;
-(void)setAddress:(NSString *)address;
-(void)addBacktrack:(NSString *)address withUnread:(BOOL)unread;
-(BOOL)handleKeyDown:(unichar)keyChar withFlags:(NSUInteger)flags;
-(void)setStatusMessage:(NSString *)newStatusText persist:(BOOL)persistenceFlag;
-(void)startProgressIndicator;
-(void)stopProgressIndicator;
-(NSString *)applicationVersion;
@end

