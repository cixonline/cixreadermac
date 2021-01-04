//
//  SmartFolder.h
//  CIXReader
//
//  Created by Steve Palmer on 12/11/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "FolderBase.h"
#import "Folder.h"

typedef BOOL (^criteriaBlock)(Message *);

#define IsSmartFolder(f)   ([(f) isKindOfClass:SmartFolder.class])

@interface SmartFolder : FolderBase<FolderProtocol>

@property (atomic, readwrite) NSString * criteria;
@property (assign, readwrite) criteriaBlock containComparator;

@end
