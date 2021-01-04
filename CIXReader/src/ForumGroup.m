//
//  ForumGroup.m
//  CIXReader
//
//  Created by Steve Palmer on 08/01/2015.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "ForumGroup.h"
#import "CIX.h"

@implementation ForumGroup

/* Return the unread count on this folder.
 */
-(NSInteger)unread
{
    return CIX.folderCollection.totalUnread;
}
@end
