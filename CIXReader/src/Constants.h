//
//  Constants.h
//  CIXReader
//
//  Created by Steve Palmer on 04/08/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#ifndef CIXReader_Constants_h
#define CIXReader_Constants_h

typedef enum {
    AppViewNone,
    AppViewMail,
    AppViewForum,
    AppViewTopic,
    AppViewDirectory,
    AppViewWelcome
} AppView;

typedef enum {
    AppBadgeNone,
    AppBadgeUnreadCount,
    AppBadgeUnreadPriorityCount
} AppBadge;

extern NSString * MAPref_DefaultSignature;
extern NSString * MAPref_DownloadInlineImages;
extern NSString * MAPref_IgnoreMarkup;
extern NSString * MAPref_StartOffline;
extern NSString * MAPref_ViewStatusBar;
extern NSString * MAPref_FirstRun;
extern NSString * MAPref_LastUserName;
extern NSString * MAPref_EnableLogFile;
extern NSString * MAPref_ArchiveLogFile;
extern NSString * MAPref_CumulativeLogFile;
extern NSString * MAPref_UseBeta;
extern NSString * MAPref_FolderFont;
extern NSString * MAPref_ArticleListFont;
extern NSString * MAPref_ShowAllTopics;
extern NSString * MAPref_MessageFont;
extern NSString * MAPref_ActiveStyleName;
extern NSString * MAPref_ActiveTextSizeMultiplier;
extern NSString * MAPref_LastAddress;
extern NSString * MAPref_Signatures;
extern NSString * MAPref_TopicViewLayout;
extern NSString * MAPref_MailViewLayout;
extern NSString * MAPref_FoldersViewLayout;
extern NSString * MAPref_BacktrackQueueSize;
extern NSString * MAPref_AppBadgeMode;
extern NSString * MAPref_UseBetaAPI;
extern NSString * MAPref_UseFastSync;
extern NSString * MAPref_CacheCleanUpFrequency;
extern NSString * MAPref_LastCacheCleanupDate;
extern NSString * MAPref_ShowIgnored;
extern NSString * MAPref_GroupByConv;
extern NSString * MAPref_CollapseConv;
extern NSString * MAPRef_StartAtHomePage;

extern const NSInteger CR_Default_BackTrackQueueSize;

// Notification constants
#define MA_Notify_StatusBarChanged      @"CR_Notify_StatusBarChanged"
#define MA_Notify_StyleChange           @"CR_Notify_StyleChange"
#define MA_Notify_FolderFontChange      @"CR_Notify_FolderFontChange"
#define MA_Notify_ArticleListFontChange @"CR_Notify_ArticleListFontChange"
#define MA_Notify_ShowAllTopicsChange   @"CR_Notify_ShowAllTopicsChange"
#define MA_Notify_MessageFontChange     @"CR_Notify_MessageFontChange"
#define MA_Notify_SignaturesChange      @"CR_Notify_SignaturesChange"
#define MA_Notify_ArticleViewChange     @"CR_Notify_ArticleViewChange"
#define MA_Notify_AppBadgeModeChanged   @"CR_Notify_AppBadgeModeChanged"
#define MA_Notify_ThreadPaneChanged     @"CR_Notify_ThreadPaneChanged"

extern NSString * CR_PBoardType_FolderList;
extern NSString * CR_PBoardType_MessageList;
extern NSString * CR_DefaultStyleName;
#endif
