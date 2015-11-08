//
//  CIXReaderApp.h
//  CIXReader
//
//  Created by Steve Palmer on 22/11/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "Folder.h"

@interface CIXReaderApp : NSApplication

// Mark all articles read
-(id)handleMarkAllRead:(NSScriptCommand *)cmd;

// General read-only properties.
-(NSString *)applicationVersion;
-(NSArray *)folders;
-(NSInteger)totalUnreadCount;
-(NSString *)currentTextSelection;

// Change folder selection
-(Folder *)currentFolder;
-(void)setCurrentFolder:(Folder *)newCurrentFolder;

// Current article
-(Message *)currentMessage;

// Preference getters
-(NSString *)folderListFont;
-(int)folderListFontSize;
-(NSString *)articleListFont;
-(int)articleListFontSize;
-(BOOL)statusBarVisible;

// Preference setters
-(void)setFolderListFont:(NSString *)newFontName;
-(void)setFolderListFontSize:(int)newFontSize;
-(void)setArticleListFont:(NSString *)newFontName;
-(void)setArticleListFontSize:(int)newFontSize;
-(void)setStatusBarVisible:(BOOL)flag;
@end
