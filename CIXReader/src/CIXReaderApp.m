//
//  CIXReaderApp.m
//  CIXReader
//
//  Created by Steve Palmer on 22/11/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "CIXReaderApp.h"
#import "AppDelegate.h"
#import "Preferences.h"

@implementation CIXReaderApp

/* Given a script argument object, this code attempts to determine
 * an array of folders from that argument. If any argument is NOT a folder
 * type, we return nil and report an error back to the script command.
 */
-(NSArray *)evaluatedArrayOfFolders:(id)argObject withCommand:(NSScriptCommand *)cmd
{
    NSMutableArray * newArgArray = [NSMutableArray array];
    BOOL hasError = NO;
    
    if ([argObject isKindOfClass:[Folder class]])
        [newArgArray addObject:argObject];
    
    else if ([argObject isKindOfClass:[NSArray class]])
    {
        NSArray * argArray = (NSArray *)argObject;
        int index;
        
        for (index = 0; index < [argArray count] && !hasError; ++index)
        {
            id argItem = argArray[index];
            if ([argItem isKindOfClass:[Folder class]])
                [newArgArray addObject:argItem];
            else if ([argItem isKindOfClass:[NSScriptObjectSpecifier class]])
            {
                id evaluatedItem = [argItem objectsByEvaluatingSpecifier];
                if ([evaluatedItem isKindOfClass:[Folder class]])
                    [newArgArray addObject:evaluatedItem];
                else if ([evaluatedItem isKindOfClass:[NSArray class]])
                {
                    NSArray * newArray = [self evaluatedArrayOfFolders:evaluatedItem withCommand:cmd];
                    if (newArray == nil)
                        return nil;
                    
                    [newArgArray addObjectsFromArray:newArray];
                }
            }
            else
                hasError = YES;
        }
    }
    if (!hasError)
        return newArgArray;
    
    // At least one of the arguments didn't evaluate to a Folder object
    [cmd setScriptErrorNumber:errASIllegalFormalParameter];
    [cmd setScriptErrorString:@"Argument must evaluate to a valid folder"];
    return nil;
}

/* Mark all articles in the specified folder as read
 */
-(id)handleMarkAllRead:(NSScriptCommand *)cmd
{
    NSDictionary * args = [cmd evaluatedArguments];
    NSArray * argArray = [self evaluatedArrayOfFolders:args[@"Folder"] withCommand:cmd];
    if (argArray != nil)
    {
        for (Folder * folder in argArray)
            [folder markAllRead];
    }
    return nil;
}

/* Return the applications version number.
 */
-(NSString *)applicationVersion
{
    AppDelegate * app = (AppDelegate *)[NSApp delegate];
    return [app applicationVersion];
}

/* Return a flat array of all folders
 */
-(NSArray *)folders
{
    return [CIX.folderCollection allFolders];
}

/* Return the total number of unread articles.
 */
-(NSInteger)totalUnreadCount
{
    return [CIX totalUnread];
}

/* Returns the current selected text from the article view or an empty
 * string if there is no selection.
 */
-(NSString *)currentTextSelection
{
    return @"";
}

/* Current selected folder.
 */
-(Folder *)currentFolder
{
    AppDelegate * app = (AppDelegate *)[NSApp delegate];
    return app.currentFolder;
}

/* Change the current selected folder.
 */
-(void)setCurrentFolder:(Folder *)newCurrentFolder
{
}

/* Current selected message
 */
-(Message *)currentMessage
{
    AppDelegate * app = (AppDelegate *)[NSApp delegate];
    return app.currentMessage;
}

/* Accessor getters
 * These thunk through the standard preferences.
 */
-(NSString *)folderListFont			{ return [[Preferences standardPreferences] folderListFont]; }
-(int)folderListFontSize			{ return [[Preferences standardPreferences] folderListFontSize]; }
-(NSString *)articleListFont		{ return [[Preferences standardPreferences] articleListFont]; }
-(int)articleListFontSize			{ return [[Preferences standardPreferences] articleListFontSize]; }
-(BOOL)statusBarVisible				{ return [[Preferences standardPreferences] viewStatusBar]; }

/* Accessor setters
 * These thunk through the standard preferences.
 */
-(void)setFolderListFont:(NSString *)newFontName	{ [[Preferences standardPreferences] setFolderListFont:newFontName]; }
-(void)setFolderListFontSize:(int)newFontSize		{ [[Preferences standardPreferences] setFolderListFontSize:newFontSize]; }
-(void)setArticleListFont:(NSString *)newFontName	{ [[Preferences standardPreferences] setArticleListFont:newFontName]; }
-(void)setArticleListFontSize:(int)newFontSize		{ [[Preferences standardPreferences] setArticleListFontSize:newFontSize]; }
-(void)setStatusBarVisible:(BOOL)flag				{ [[Preferences standardPreferences] setViewStatusBar:flag]; }
@end
