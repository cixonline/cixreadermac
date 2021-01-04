//
//  TopicFolder.h
//  CIXReader
//
//  Created by Steve Palmer on 22/08/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "FolderBase.h"
#import "Folder.h"

@interface TopicFolder : FolderBase<FolderProtocol>

@property Folder * folder;

// Accessors
-(id)initWithFolder:(Folder *)theFolder;
-(BOOL)canMarkAllRead;
-(void)resign;
@end
