//
//  Preferences.m
//  CIXReader
//
//  Created by Steve Palmer on 04/08/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "Preferences.h"
#import "Signatures.h"
#import "autorevision.h"
#import "Sparkle/Sparkle.h"

// The default preferences object
static Preferences * _standardPreferences = nil;

@implementation Preferences

/* Return the single set of CIXReader wide preferences object.
 */
+(Preferences *)standardPreferences
{
    if (_standardPreferences == nil)
        _standardPreferences = [[Preferences alloc] init];

    return _standardPreferences;
}

/* The designated initialiser.
 */
-(id)init
{
	if ((self = [super init]) != nil)
	{
		NSDictionary * defaults = [self allocFactoryDefaults];

        _userPrefs = [NSUserDefaults standardUserDefaults];
        [_userPrefs registerDefaults:defaults];
		
		// Load those settings that we cache.
        _downloadInlineImages = [self boolForKey:MAPref_DownloadInlineImages];
        _ignoreMarkup = [self boolForKey:MAPref_IgnoreMarkup];
        _showIgnored = [self boolForKey:MAPref_ShowIgnored];
        _groupByConv = [self boolForKey:MAPref_GroupByConv];
        _collapseConv = [self boolForKey:MAPref_CollapseConv];
        _startOffline = [self boolForKey:MAPref_StartOffline];
        _viewStatusBar = [self boolForKey:MAPref_ViewStatusBar];
        _firstRun = [self boolForKey:MAPref_FirstRun];
        _enableLogFile = [self boolForKey:MAPref_EnableLogFile];
        _archiveLogFile = [self boolForKey:MAPref_ArchiveLogFile];
        _cumulativeLogFile = [self boolForKey:MAPref_CumulativeLogFile];
        _lastUser = [self stringForKey:MAPref_LastUserName];
        _useBeta = [self boolForKey:MAPref_UseBeta];
        _useBetaAPI = [self boolForKey:MAPref_UseBetaAPI];
        _useFastSync = [self boolForKey:MAPref_UseFastSync];
        _lastAddress = [self stringForKey:MAPref_LastAddress];
		_folderFont = [NSKeyedUnarchiver unarchiveObjectWithData:[_userPrefs objectForKey:MAPref_FolderFont]];
        _articleFont = [NSKeyedUnarchiver unarchiveObjectWithData:[_userPrefs objectForKey:MAPref_ArticleListFont]];
        _messageFont = [NSKeyedUnarchiver unarchiveObjectWithData:[_userPrefs objectForKey:MAPref_MessageFont]];
        _showAllTopics = [self boolForKey:MAPref_ShowAllTopics];
        _displayStyle = [_userPrefs valueForKey:MAPref_ActiveStyleName];
		_textSizeMultiplier = [[_userPrefs valueForKey:MAPref_ActiveTextSizeMultiplier] floatValue];
        _defaultSignature = [self stringForKey:MAPref_DefaultSignature];
        _appBadgeMode = (AppBadge)[self integerForKey:MAPref_AppBadgeMode];
        _cacheCleanUpFrequency = [self integerForKey:MAPref_CacheCleanUpFrequency];
        _lastCacheCleanupDate = [self objectForKey:MAPref_LastCacheCleanupDate];
        _startAtHomePage = [self boolForKey:MAPRef_StartAtHomePage];
        
		// Sparkle autoupdate
        [self setSparkleURL];
	}
	return self;
}

/* The standard class initialization object.
 */
-(NSDictionary *)allocFactoryDefaults
{
	// Set the preference defaults
	NSMutableDictionary * defaultValues = [[NSMutableDictionary alloc] init];

	NSData * defaultFolderFont = [NSKeyedArchiver archivedDataWithRootObject:[NSFont fontWithName:@"LucidaGrande" size:11.0]];
    NSData * defaultArticleListFont = [NSKeyedArchiver archivedDataWithRootObject:[NSFont fontWithName:@"LucidaGrande" size:11.0]];
    NSData * defaultPlainTextFont = [NSKeyedArchiver archivedDataWithRootObject:[NSFont fontWithName:@"Courier New" size:12.0]];
	
	NSNumber * boolYes = @(YES);
	NSNumber * boolNo = @(NO);
    
    defaultValues[MAPref_UseBeta]= (VCS_BETA) ? boolYes : boolNo;
    defaultValues[MAPref_UseBetaAPI]= boolNo;
    defaultValues[MAPref_UseFastSync] = boolYes;
    defaultValues[MAPref_FirstRun] = boolYes;
    defaultValues[MAPref_ViewStatusBar] = boolNo;
    defaultValues[MAPref_StartOffline] = boolNo;
    defaultValues[MAPref_IgnoreMarkup] = boolNo;
    defaultValues[MAPref_ShowIgnored] = boolYes;
    defaultValues[MAPref_GroupByConv] = boolYes;
    defaultValues[MAPRef_StartAtHomePage] = boolYes;
    defaultValues[MAPref_CollapseConv] = boolNo;
    defaultValues[MAPref_ArchiveLogFile] = boolNo;
    defaultValues[MAPref_CumulativeLogFile] = boolNo;
    defaultValues[MAPref_EnableLogFile] = boolYes;
    defaultValues[MAPref_DownloadInlineImages] = boolYes;
    defaultValues[MAPref_ShowAllTopics] = boolNo;
    defaultValues[MAPref_ActiveTextSizeMultiplier] = @(1.0f);
    defaultValues[MAPref_BacktrackQueueSize] = @(CR_Default_BackTrackQueueSize);
    defaultValues[MAPref_ActiveStyleName] = CR_DefaultStyleName;
    defaultValues[MAPref_DefaultSignature] = [Signatures noSignaturesString];
    defaultValues[MAPref_FolderFont] = defaultFolderFont;
    defaultValues[MAPref_ArticleListFont] = defaultArticleListFont;
    defaultValues[MAPref_MessageFont] = defaultPlainTextFont;
    defaultValues[MAPref_AppBadgeMode] = @(2);
    defaultValues[MAPref_LastCacheCleanupDate] = [NSDate date];
    defaultValues[MAPref_CacheCleanUpFrequency] = @(0);

	return defaultValues;
}

/* Save the user preferences back to where we loaded them from.
 */
-(void)savePreferences
{
	[_userPrefs synchronize];
}

/* Return whether the specified key has a value in the preferences.
 */
-(BOOL)hasKey:(NSString *)keyname
{
    return [_userPrefs objectForKey:keyname] != nil;
}

/* Sets the value of the specified default to the given boolean value.
 */
-(void)setBool:(BOOL)value forKey:(NSString *)defaultName
{
    [_userPrefs setObject:@(value) forKey:defaultName];
}

/* Returns the boolean value of the given default object.
 */
-(BOOL)boolForKey:(NSString *)defaultName
{
	return [[_userPrefs valueForKey:defaultName] boolValue];
}

/* Sets the value of the specified default to the given string.
 */
-(void)setString:(NSString *)value forKey:(NSString *)defaultName
{
	[_userPrefs setObject:value forKey:defaultName];
}

/* Returns the string value of the given default object.
 */
-(NSString *)stringForKey:(NSString *)defaultName
{
	return [_userPrefs valueForKey:defaultName];
}

/* Sets the value of the specified default to the given integer value.
 */
-(void)setInteger:(NSInteger)value forKey:(NSString *)defaultName
{
	[_userPrefs setObject:[NSNumber numberWithLong:value] forKey:defaultName];
}

/* Returns the integer value of the given default object.
 */
-(NSInteger)integerForKey:(NSString *)defaultName
{
	return [[_userPrefs valueForKey:defaultName] intValue];
}

/* Sets the value of the specified default to the given object.
 */
-(void)setObject:(id)value forKey:(NSString *)defaultName
{
	[_userPrefs setObject:value forKey:defaultName];
}

/* Return the value of the given default object.
 */
-(id)objectForKey:(NSString *)defaultName
{
    return [_userPrefs objectForKey:defaultName];
}

/* Returns the flag that indicates whether inline images are downloaded.
 */
-(BOOL)downloadInlineImages
{
    return _downloadInlineImages;
}

/* Toggle the flag that indicates whether inline images are downloaded.
 */
-(void)setDownloadInlineImages:(BOOL)flag
{
    if (flag != _downloadInlineImages)
    {
        _downloadInlineImages = flag;
        [self setBool:flag forKey:MAPref_DownloadInlineImages];
        [[NSNotificationCenter defaultCenter] postNotificationName:MA_Notify_ArticleViewChange object:nil];
    }
}

/* Returns the flag that indicates whether CIX markup in messages is ignored.
 */
-(BOOL)ignoreMarkup
{
    return _ignoreMarkup;
}

/* Toggle the flag that indicates whether CIX markup in messages is ignored.
 */
-(void)setIgnoreMarkup:(BOOL)flag
{
    if (flag != _ignoreMarkup)
    {
        _ignoreMarkup = flag;
        [self setBool:flag forKey:MAPref_IgnoreMarkup];
        [[NSNotificationCenter defaultCenter] postNotificationName:MA_Notify_ArticleViewChange object:nil];
    }
}

/* Returns the flag that indicates whether ignored messages are displayed or not.
 */
-(BOOL)showIgnored
{
    return _showIgnored;
}

/* Toggle the flag that indicates whether ignored messages are displayed or not.
 */
-(void)setShowIgnored:(BOOL)flag
{
    if (flag != _showIgnored)
    {
        _showIgnored = flag;
        [self setBool:flag forKey:MAPref_ShowIgnored];
        [[NSNotificationCenter defaultCenter] postNotificationName:MA_Notify_ThreadPaneChanged object:nil];
    }
}

/* Returns the flag that indicates whether we group threads by conversation.
 */
-(BOOL)groupByConv
{
    return _groupByConv;
}

/* Toggle the flag that indicates whether we group threads by conversation.
 */
-(void)setGroupByConv:(BOOL)flag
{
    if (flag != _groupByConv)
    {
        _groupByConv = flag;
        [self setBool:flag forKey:MAPref_GroupByConv];
        [[NSNotificationCenter defaultCenter] postNotificationName:MA_Notify_ThreadPaneChanged object:nil];
    }
}

/* Returns the flag that indicates whether we collapse conversations by default.
 */
-(BOOL)collapseConv
{
    return _collapseConv;
}

/* Toggle the flag that indicates whether we collapse conversations by default.
 */
-(void)setCollapseConv:(BOOL)flag
{
    if (flag != _collapseConv)
    {
        _collapseConv = flag;
        [self setBool:flag forKey:MAPref_CollapseConv];
        [[NSNotificationCenter defaultCenter] postNotificationName:MA_Notify_ThreadPaneChanged object:nil];
    }
}

/* Return the topic view layout.
 */
-(NSArray *)topicViewLayout
{
    return [self objectForKey:MAPref_TopicViewLayout];
}

/* Save the topic view layout.
 */
-(void)setTopicViewLayout:(NSArray *)layout
{
    [self setObject:layout forKey:MAPref_TopicViewLayout];
}

/* Return the mail view layout.
 */
-(NSArray *)mailViewLayout
{
    return [self objectForKey:MAPref_MailViewLayout];
}

/* Save the mail view layout.
 */
-(void)setMailViewLayout:(NSArray *)layout
{
    [self setObject:layout forKey:MAPref_MailViewLayout];
}

/* Return the folders view layout.
 */
-(NSArray *)foldersViewLayout
{
    return [self objectForKey:MAPref_FoldersViewLayout];
}

/* Save the folders view layout.
 */
-(void)setFoldersViewLayout:(NSArray *)layout
{
    [self setObject:layout forKey:MAPref_FoldersViewLayout];
}

/* Returns the flag that indicates whether CIXReader starts offline.
 */
-(BOOL)startOffline
{
    return _startOffline;
}

/* Toggle the flag that indicates whether CIXReader starts offline.
 */
-(void)setStartOffline:(BOOL)flag
{
    _startOffline = flag;
    [self setBool:flag forKey:MAPref_StartOffline];
}

/* Returns the length of the back track queue.
 */
-(NSInteger)backTrackQueueSize
{
    return [self integerForKey:MAPref_BacktrackQueueSize];
}

/* Returns the flag that indicates whether the status bar is shown.
 */
-(BOOL)viewStatusBar
{
    return _viewStatusBar;
}

/* Toggle the flag that indicates whether the status bar is shown.
 */
-(void)setViewStatusBar:(BOOL)flag
{
    if (_viewStatusBar != flag)
    {
        _viewStatusBar = flag;
        [self setBool:flag forKey:MAPref_ViewStatusBar];
		[[NSNotificationCenter defaultCenter] postNotificationName:MA_Notify_StatusBarChanged object:nil];
    }
}

/* Return the first run flag.
 */
-(BOOL)firstRun
{
    return _firstRun;
}

/* Set or clear the first run flag.
 */
-(void)setFirstRun:(BOOL)flag
{
    _firstRun = flag;
    [self setBool:flag forKey:MAPref_FirstRun];
}

/* Return whether or not log files are enabled.
 */
-(BOOL)enableLogFile
{
    return _enableLogFile;
}

/* Set or clear the flag for enabling log files.
 */
-(void)setEnableLogFile:(BOOL)flag
{
    _enableLogFile = flag;
    [self setBool:flag forKey:MAPref_EnableLogFile];
}

/* Return whether or not log files are archived.
 */
-(BOOL)archiveLogFile
{
    return _archiveLogFile;
}

/* Set or clear the flag for archiving log files.
 */
-(void)setArchiveLogFile:(BOOL)flag
{
    _archiveLogFile = flag;
    [self setBool:flag forKey:MAPref_ArchiveLogFile];
}

/* Return whether the log file is cumulative.
 */
-(BOOL)cumulativeLogFile
{
    return _cumulativeLogFile;
}

/* Set or clear the flag for cumulative log files
 */
-(void)setCumulativeLogFile:(BOOL)flag
{
    _cumulativeLogFile = flag;
    [self setBool:flag forKey:MAPref_CumulativeLogFile];
}

/* Return whether to use the beta API.
 */
-(BOOL)useBetaAPI
{
    return _useBetaAPI;
}

/* Set or clear the flag for using the beta API.
 */
-(void)setUseBetaAPI:(BOOL)flag
{
    _useBetaAPI = flag;
    [self setBool:flag forKey:MAPref_UseBetaAPI];
}

/* Return whether Fast Sync is enabled
 */
-(BOOL)useFastSync
{
    return _useFastSync;
}

/* Set or clear the flag for enabling Fast Sync.
 */
-(void)setUseFastSync:(BOOL)flag
{
    _useFastSync = flag;
    [self setBool:flag forKey:MAPref_UseFastSync];
}

/* Return the name of the last logged on user.
 */
-(NSString *)lastUser
{
    return _lastUser;
}

/* Save the name of the last logged on user.
 */
-(void)setLastUser:(NSString *)newLastUser
{
    _lastUser = newLastUser;
    [self setString:newLastUser forKey:MAPref_LastUserName];
}

/* Return the last address navigated to.
 */
-(NSString *)lastAddress
{
    return _lastAddress;
}

/* Set the last address navigated to.
 */
-(void)setLastAddress:(NSString *)newLastAddress
{
    if (newLastAddress != nil)
    {
        _lastAddress = newLastAddress;
        [self setString:newLastAddress forKey:MAPref_LastAddress];
    }
}

/* Set the default signature.
 */
-(void)setDefaultSignature:(NSString *)value
{
    _defaultSignature = value;
    [self setString:value forKey:MAPref_DefaultSignature];
}

/* Return the default signature.
 */
-(NSString *)defaultSignature
{
    return _defaultSignature;
}

/* Return whether we automatically check for updates.
 */
-(BOOL)checkForUpdates
{
    return [[SUUpdater sharedUpdater] automaticallyChecksForUpdates];
}

/* Set whether or not we automatically check for updates
 */
-(void)setCheckForUpdates:(BOOL)flag
{
    [[SUUpdater sharedUpdater] setAutomaticallyChecksForUpdates:flag];
}

/* Return whether we install beta releases.
 */
-(BOOL)useBeta
{
    return _useBeta;
}

/* Sets whether we install beta releases.
 */
-(void)setUseBeta:(BOOL)flag
{
    _useBeta = flag;
    [self setBool:flag forKey:MAPref_UseBeta];
    [self setSparkleURL];
}

/* Set the URL that Sparkle uses for checking for updates
 */
-(void)setSparkleURL
{
    NSString * updateURL = [NSString stringWithFormat:@"https://cixreader.cixhosting.co.uk/cixreader/osx/%@/appcast.xml", (_useBeta ? @"beta" : @"release")];
    [[SUUpdater sharedUpdater] setFeedURL:[NSURL URLWithString:updateURL]];
}

/* Retrieve the name of the font used by the editors.
 */
-(NSString *)messageFont
{
    return [_messageFont fontName];
}

/* Retrieve the size of the font used by the editors.
 */
-(int)messageFontSize
{
    return [_messageFont pointSize];
}

/* Set the new font used by the message editor.
 */
-(void)setMessageFont:(NSString *)newFontName
{
    _messageFont = [NSFont fontWithName:newFontName size:[self messageFontSize]];
    [self setObject:[NSKeyedArchiver archivedDataWithRootObject:_messageFont] forKey:MAPref_MessageFont];
    [[NSNotificationCenter defaultCenter] postNotificationName:MA_Notify_MessageFontChange object:_messageFont];
}

/* Set the size of the new font used by the message editor.
 */
-(void)setMessageFontSize:(int)newFontSize
{
    _messageFont = [NSFont fontWithName:[self messageFont] size:newFontSize];
    [self setObject:[NSKeyedArchiver archivedDataWithRootObject:_messageFont] forKey:MAPref_MessageFont];
    [[NSNotificationCenter defaultCenter] postNotificationName:MA_Notify_MessageFontChange object:_messageFont];
}

/* folderListFont
 * Retrieve the name of the font used in the folder list
 */
-(NSString *)folderListFont
{
	return [_folderFont fontName];
}

/* folderListFontSize
 * Retrieve the size of the font used in the folder list
 */
-(int)folderListFontSize
{
	return [_folderFont pointSize];
}

/* setFolderListFont
 * Retrieve the name of the font used in the folder list
 */
-(void)setFolderListFont:(NSString *)newFontName
{
	_folderFont = [NSFont fontWithName:newFontName size:[self folderListFontSize]];
	[self setObject:[NSKeyedArchiver archivedDataWithRootObject:_folderFont] forKey:MAPref_FolderFont];
	[[NSNotificationCenter defaultCenter] postNotificationName:MA_Notify_FolderFontChange object:_folderFont];
}

/* setFolderListFontSize
 * Changes the size of the font used in the folder list.
 */
-(void)setFolderListFontSize:(int)newFontSize
{
	_folderFont = [NSFont fontWithName:[self folderListFont] size:newFontSize];
	[self setObject:[NSKeyedArchiver archivedDataWithRootObject:_folderFont] forKey:MAPref_FolderFont];
	[[NSNotificationCenter defaultCenter] postNotificationName:MA_Notify_FolderFontChange object:_folderFont];
}

/* articleListFont
 * Retrieve the name of the font used in the article list
 */
-(NSString *)articleListFont
{
    return [_articleFont fontName];
}

/* articleListFontSize
 * Retrieve the size of the font used in the article list
 */
-(int)articleListFontSize
{
    return [_articleFont pointSize];
}

/* setArticleListFont
 * Retrieve the name of the font used in the article list
 */
-(void)setArticleListFont:(NSString *)newFontName
{
    _articleFont = [NSFont fontWithName:newFontName size:[self articleListFontSize]];
    [self setObject:[NSKeyedArchiver archivedDataWithRootObject:_articleFont] forKey:MAPref_ArticleListFont];
    [[NSNotificationCenter defaultCenter] postNotificationName:MA_Notify_ArticleListFontChange object:_articleFont];
}

/* setArticleListFontSize
 * Changes the size of the font used in the article list.
 */
-(void)setArticleListFontSize:(int)newFontSize
{
    _articleFont = [NSFont fontWithName:[self articleListFont] size:newFontSize];
    [self setObject:[NSKeyedArchiver archivedDataWithRootObject:_articleFont] forKey:MAPref_ArticleListFont];
    [[NSNotificationCenter defaultCenter] postNotificationName:MA_Notify_ArticleListFontChange object:_articleFont];
}

/* Return whether the folder view shows all topics or just recent ones.
 */
-(BOOL)showAllTopics
{
    return _showAllTopics;
}

/* Set whether the folder view shows all or recent topics.
 */
-(void)setShowAllTopics:(BOOL)flag
{
    if (_showAllTopics != flag)
    {
        _showAllTopics = flag;
        [self setBool:flag forKey:MAPref_ShowAllTopics];
        [[NSNotificationCenter defaultCenter] postNotificationName:MA_Notify_ShowAllTopicsChange object:nil];
    }
}

/* Retrieves the name of the current article display style.
 */
-(NSString *)displayStyle
{
    return _displayStyle;
}

/* Changes the style used for displaying articles
 */
-(void)setDisplayStyle:(NSString *)newStyleName
{
    [self setDisplayStyle:newStyleName withNotification:YES];
}

/* Changes the style used for displaying articles and optionally sends a notification.
 */
-(void)setDisplayStyle:(NSString *)newStyleName withNotification:(BOOL)flag
{
    if (![_displayStyle isEqualToString:newStyleName])
    {
        _displayStyle = newStyleName;
        [self setString:_displayStyle forKey:MAPref_ActiveStyleName];
        if (flag)
            [[NSNotificationCenter defaultCenter] postNotificationName:MA_Notify_StyleChange object:nil];
    }
}

/* Return the textSizeMultiplier to be applied to an ArticleView
 */
-(float)textSizeMultiplier
{
    return _textSizeMultiplier;
}

/* setTextSizeMultiplier
 * Changes the textSizeMultiplier to be applied to an ArticleView
 */
-(void)setTextSizeMultiplier:(float)newValue
{
    if (newValue != _textSizeMultiplier)
    {
        _textSizeMultiplier = newValue;
        [self setObject:[NSNumber numberWithFloat:newValue] forKey:MAPref_ActiveTextSizeMultiplier];
        [[NSNotificationCenter defaultCenter] postNotificationName:MA_Notify_StyleChange object:nil];
    }
}

/* Return the current application badge mode
 */
-(AppBadge)appBadgeMode
{
    return _appBadgeMode;
}

/* Change the current application badge mode.
 */
-(void)setAppBadgeMode:(AppBadge)value
{
    if (value != _appBadgeMode)
    {
        _appBadgeMode = value;
        [self setInteger:value forKey:MAPref_AppBadgeMode];
        [[NSNotificationCenter defaultCenter] postNotificationName:MA_Notify_AppBadgeModeChanged object:nil];
    }
}

/* Return the cache clean up frequency, expressed in days.
 */
-(NSInteger)cacheCleanUpFrequency
{
    return _cacheCleanUpFrequency;
}

/* Update the cache clean up frequency
 */
-(void)setCacheCleanUpFrequency:(NSInteger)frequency
{
    _cacheCleanUpFrequency = frequency;
    [self setInteger:_cacheCleanUpFrequency forKey:MAPref_CacheCleanUpFrequency];
}

/* Return the date of the last cache cleanup
 */
-(NSDate *)lastCacheCleanUpDate
{
    return _lastCacheCleanupDate;
}

/* Set the date of the last cache cleanup.
 */
-(void)setLastCacheCleanUpDate:(NSDate *)date
{
    _lastCacheCleanupDate = date;
    [self setObject:date forKey:MAPref_LastCacheCleanupDate];
}

/* Set the flag which specifies whether we start CIXReader at the home page.
 */
-(BOOL)startAtHomePage
{
    return _startAtHomePage;
}

/* Change the flag which specifies whether we start CIXReader at the home page.
 */
-(void)setStartAtHomePage:(BOOL)flag
{
    if (flag != _startAtHomePage)
    {
        _startAtHomePage = flag;
        [self setBool:flag forKey:MAPRef_StartAtHomePage];
    }
}
@end
