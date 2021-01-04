//
//  FolderBase.h
//  CIXReader
//
//  Created by Steve Palmer on 22/08/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "Constants.h"
#import "Folder.h"

@protocol FolderProtocol <NSObject>
    -(ID_type)ID;
    -(AppView)viewForFolder;
    -(NSString *)fullName;
    -(NSImage *)icon;
    -(NSString *)address;
    -(NSInteger)unread;
    -(NSInteger)unreadPriority;
    -(FolderFlags)flags;
    -(void)delete;
    -(BOOL)canDelete;
    -(int)lastIndex;
    -(NSArray *)items;
    -(BOOL)refresh;
    -(BOOL)canContain:(id)value;
    -(void)markAllRead;
    -(BOOL)allowsScopedSearch;
@end

@interface FolderBase : NSTreeNode<FolderProtocol>

@property NSString * name;
@property int lastIndex;

@end
