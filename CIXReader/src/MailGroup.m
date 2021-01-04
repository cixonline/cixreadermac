//
//  MailGroup.m
//  CIXReader
//
//  Created by Steve Palmer on 09/01/2015.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "MailGroup.h"
#import "CIX.h"

@implementation MailGroup

/* Return the unread count on this folder.
 */
-(NSInteger)unread
{
    return CIX.conversationCollection.totalUnread;
}
@end
