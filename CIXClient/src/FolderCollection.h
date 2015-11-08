//
//  FolderCollection.h
//  CIXClient
//
//  Created by Steve Palmer on 21/08/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "Folder.h"

@interface FolderCollection : NSObject <NSFastEnumeration> {
    NSMutableDictionary * _folders;
    NSMutableDictionary * _foldersByName;
    NSArray * _allFolders;
    Folder * _root;
    BOOL _isInRefresh;
}

// Accessors
-(void)sync;
-(void)closeSync;
-(void)refresh:(BOOL)useFastSync;
-(NSArray *)allFolders;
-(NSArray *)messagesWithCriteria:(NSString *)criteria;
-(void)add:(Folder *)folder;
-(void)remove:(Folder *)folder;
-(BOOL)isJoined:(NSString *)forumName;
-(Folder *)folderByID:(ID_type)ID;
-(Folder *)folderByName:(NSString *)forumName;
-(NSInteger)totalUnread;
-(NSInteger)totalUnreadPriority;
-(void)refreshInterestingThreads;
@end
