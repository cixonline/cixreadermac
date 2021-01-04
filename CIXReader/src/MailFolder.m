//
//  MailFolder.m
//  CIXReader
//
//  Created by Steve Palmer on 29/08/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "MailFolder.h"
#import "CIX.h"

@implementation MailFolder

/* Initialise a mail folder with the specified name and icon.
 */
-(id)initWithName:(NSString *)name andImage:(NSImage *)image
{
    if ((self = [super init]) != nil)
    {
        [self setName:name];
        [self setIcon:image];
    }
    return self;
}

/* Return the type of view for this folder.
 */
-(AppView)viewForFolder
{
    return AppViewMail;
}

/* Return the unique ID of this folder. For topic folders,
 * this will be a positive integer > 0.
 */
-(ID_type)ID
{
    return -1;
}

/* Return the address of this folder
 */
-(NSString *)address
{
    return @"cixmailbox:inbox";
}

/* Return the unread count on this folder.
 */
-(NSInteger)unread
{
    return CIX.conversationCollection.totalUnread;
}

/* Refresh the items returned by this folder.
 */
-(BOOL)refresh
{
    [CIX.conversationCollection refresh];
    return YES;
}

/* Can do scoped searches in mail folders.
 */
-(BOOL)allowsScopedSearch
{
    return YES;
}

/* Return the collection of all items in the folder.
 */
-(NSArray *)items
{
    return CIX.conversationCollection.allConversations;
}
@end
