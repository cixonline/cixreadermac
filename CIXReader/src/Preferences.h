//
//  Preferences.h
//  CIXReader
//
//  Created by Steve Palmer on 04/08/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "Constants.h"

@interface Preferences : NSObject {
@private
    id _userPrefs;
    NSString * _lastUser;
    NSString * _lastAddress;
    NSString * _defaultSignature;
    BOOL _downloadInlineImages;
    BOOL _ignoreMarkup;
    BOOL _startOffline;
    BOOL _viewStatusBar;
    BOOL _firstRun;
    BOOL _enableLogFile;
    BOOL _archiveLogFile;
    BOOL _cumulativeLogFile;
    BOOL _useBeta;
    BOOL _showAllTopics;
    BOOL _useBetaAPI;
    BOOL _useFastSync;
    BOOL _showIgnored;
    BOOL _groupByConv;
    BOOL _collapseConv;
    BOOL _startAtHomePage;
	NSFont * _folderFont;
    NSFont * _articleFont;
    NSFont * _messageFont;
    NSString * _displayStyle;
    float _textSizeMultiplier;
    NSInteger _cacheCleanUpFrequency;
    AppBadge _appBadgeMode;
    NSDate * _lastCacheCleanupDate;
}

// Accessor functions
+(Preferences *)standardPreferences;
-(void)savePreferences;

-(BOOL)hasKey:(NSString *)keyname;

-(BOOL)boolForKey:(NSString *)defaultName;
-(void)setBool:(BOOL)value forKey:(NSString *)defaultName;

-(NSInteger)integerForKey:(NSString *)defaultName;
-(void)setInteger:(NSInteger)value forKey:(NSString *)defaultName;

-(BOOL)downloadInlineImages;
-(void)setDownloadInlineImages:(BOOL)flag;

-(BOOL)ignoreMarkup;
-(void)setIgnoreMarkup:(BOOL)flag;

-(BOOL)showIgnored;
-(void)setShowIgnored:(BOOL)flag;

-(BOOL)groupByConv;
-(void)setGroupByConv:(BOOL)flag;

-(BOOL)collapseConv;
-(void)setCollapseConv:(BOOL)flag;

-(BOOL)startOffline;
-(void)setStartOffline:(BOOL)flag;

-(BOOL)viewStatusBar;
-(void)setViewStatusBar:(BOOL)flag;

-(BOOL)firstRun;
-(void)setFirstRun:(BOOL)flag;

-(BOOL)enableLogFile;
-(void)setEnableLogFile:(BOOL)flag;

-(NSString *)lastAddress;
-(void)setLastAddress:(NSString *)newLastAddress;

-(BOOL)archiveLogFile;
-(void)setArchiveLogFile:(BOOL)flag;

-(BOOL)cumulativeLogFile;
-(void)setCumulativeLogFile:(BOOL)flag;

-(NSString *)lastUser;
-(void)setLastUser:(NSString *)newLastUser;

-(BOOL)checkForUpdates;
-(void)setCheckForUpdates:(BOOL)flag;

-(BOOL)useBeta;
-(void)setUseBeta:(BOOL)flag;

-(BOOL)useBetaAPI;
-(void)setUseBetaAPI:(BOOL)flag;

-(NSArray *)topicViewLayout;
-(void)setTopicViewLayout:(NSArray *)layout;

-(NSArray *)mailViewLayout;
-(void)setMailViewLayout:(NSArray *)layout;

-(NSArray *)foldersViewLayout;
-(void)setFoldersViewLayout:(NSArray *)layout;

-(NSInteger)backTrackQueueSize;

-(void)setDefaultSignature:(NSString *)value;
-(NSString *)defaultSignature;

-(NSString *)folderListFont;
-(int)folderListFontSize;
-(void)setFolderListFont:(NSString *)newFontName;
-(void)setFolderListFontSize:(int)newFontSize;

-(NSString *)articleListFont;
-(int)articleListFontSize;
-(void)setArticleListFont:(NSString *)newFontName;
-(void)setArticleListFontSize:(int)newFontSize;

-(NSString *)messageFont;
-(int)messageFontSize;;
-(void)setMessageFont:(NSString *)newFontName;
-(void)setMessageFontSize:(int)newFontSize;

-(BOOL)showAllTopics;
-(void)setShowAllTopics:(BOOL)flag;

-(BOOL)useFastSync;
-(void)setUseFastSync:(BOOL)flag;

-(NSString *)displayStyle;
-(void)setDisplayStyle:(NSString *)newStyle;
-(void)setDisplayStyle:(NSString *)newStyle withNotification:(BOOL)flag;
-(float)textSizeMultiplier;
-(void)setTextSizeMultiplier:(float)newValue;

-(AppBadge)appBadgeMode;
-(void)setAppBadgeMode:(AppBadge)value;

-(NSInteger)cacheCleanUpFrequency;
-(void)setCacheCleanUpFrequency:(NSInteger)frequency;

-(NSDate *)lastCacheCleanUpDate;
-(void)setLastCacheCleanUpDate:(NSDate *)date;

-(BOOL)startAtHomePage;
-(void)setStartAtHomePage:(BOOL)flag;
@end
