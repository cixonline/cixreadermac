//
//  Folder.h
//  CIXClient
//
//  Created by Steve Palmer on 31/07/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "MessageCollection.h"

// Folder flags
typedef enum {
    FolderFlagsReadOnly = 1,
    FolderFlagsResigned = 2,
    FolderFlagsCannotResign = 4,
    FolderFlagsOwnerCommentsOnly = 8,
    FolderFlagsJoinFailed = 16,
    FolderFlagsRecent = 32
} FolderFlags;

#define IsTopLevelFolder(f)  ((f).parentID == -1)
#define IsReadOnly(f)    (((f).flags) & FolderFlagsReadOnly)

@interface Folder : TableBase {
    MessageCollection * _messages;
    NSMutableArray * _children;
    BOOL _isFolderRefreshing;
    BOOL _refreshRequired;
}

// Accessors
@property ID_type ID;
@property ID_type parentID;
@property NSString * name;
@property NSString * displayName;
@property FolderFlags flags;
@property int treeIndex;
@property int unread;
@property int unreadPriority;
@property BOOL resignPending;
@property BOOL markReadRangePending;

// Accessors
-(Folder *)parentFolder;
-(void)add:(Folder *)folder;
-(void)remove:(Folder *)folder;
-(void)move:(Folder *)folder toBefore:(Folder *)nextFolder;
-(void)move:(Folder *)folder toAfter:(Folder *)nextFolder;
-(void)reindex;
-(NSArray *)children;
-(MessageCollection *)messages;
-(Folder *)childByName:(NSString *)name;
-(Message *)getCachedMessage:(Message *)message;
-(void)markAllRead;
-(void)delete;
-(void)resign;
-(BOOL)isRecent;
-(BOOL)isResigned;
-(BOOL)canResign;
-(BOOL)hasPending;
-(void)closeSync;
-(void)fixup;
-(BOOL)refreshRequired;
-(void)refresh;
@end
