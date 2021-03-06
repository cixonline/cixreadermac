//
//  TopicFolder.m
//  CIXReader
//
//  Created by Steve Palmer on 22/08/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "TopicFolder.h"
#import "CIX.h"

static NSImage * roTopicFolderImage;
static NSImage * topicFolderImage;
static NSImage * rootFolderImage;

@implementation TopicFolder

/* Initialise with the specified topic folder instance.
 */
-(id)initWithFolder:(Folder *)theFolder
{
    if ((self = [super init]) != nil)
    {
        if (rootFolderImage == nil)
            rootFolderImage = [NSImage imageNamed:@"smallFolder.tiff"];
        if (topicFolderImage == nil)
            topicFolderImage = [NSImage imageNamed:@"topicFolder.tiff"];
        if (roTopicFolderImage == nil)
            roTopicFolderImage = [NSImage imageNamed:@"roTopicFolder.tiff"];
        [self setFolder:theFolder];
    }
    return self;
}

/* Return the type of view for this folder.
 */
-(AppView)viewForFolder
{
    return IsTopLevelFolder(self.folder) ? AppViewForum : AppViewTopic;
}

/* Return the unique ID of this folder. For topic folders,
 * this will be a positive integer > 0.
 */
-(ID_type)ID
{
    return self.folder.ID;
}

/* Return the folder name.
 */
-(NSString *)name
{
    return self.folder.name;
}

/* Return the folder tree icon for this folder.
 */
-(NSImage *)icon
{
    if (IsTopLevelFolder(self.folder))
        return rootFolderImage;
    return (IsReadOnly(self.folder) ? roTopicFolderImage : topicFolderImage);
}

/* Return the folder full name
 */
-(NSString *)fullName
{
    if (IsTopLevelFolder([self folder]))
        return [self name];

    Folder * parentFolder = [CIX.folderCollection folderByID:[[self folder] parentID]];
    NSString * lockSymbol = IsReadOnly(self.folder) ? @" 🔒" : @"";
    return [NSString stringWithFormat:@"%@ ∙ %@%@", parentFolder.name, [self name], lockSymbol];
}

/* Return the address of this folder
 */
-(NSString *)address
{
    if (IsTopLevelFolder([self folder]))
        return [NSString stringWithFormat:@"cix:%@", [self name]];

    Folder * parentFolder = [CIX.folderCollection folderByID:[[self folder] parentID]];
    return [NSString stringWithFormat:@"cix:%@/%@", parentFolder.name, [self name]];
}

/* Delete the folder.
 */
-(void)delete
{
    NSAlert * alert = [[NSAlert alloc] init];
    
    [alert addButtonWithTitle:NSLocalizedString(@"Yes", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"No", nil)];
    [alert setMessageText:NSLocalizedString(@"Delete", nil)];
    [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(IsTopLevelFolder(self.folder) ?
                                                                           @"Do you want to delete the %@ forum?" :
                                                                           @"Do you want to delete the %@ topic?", nil), self.name]];
    
    if ([alert runModal] == NSAlertFirstButtonReturn)
        [self.folder delete:YES];
}

/* Resign this form or topic.
 */
-(void)resign
{
    NSAlert * alert = [[NSAlert alloc] init];
    
    [alert addButtonWithTitle:NSLocalizedString(@"Yes", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"No", nil)];
    [alert setMessageText:NSLocalizedString(@"Resign", nil)];
    [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(IsTopLevelFolder(self.folder) ?
                                                                           @"Do you want to resign from the %@ forum?" :
                                                                           @"Do you want to resign from the %@ topic?", nil), self.name]];
    
    if ([alert runModal] == NSAlertFirstButtonReturn)
        [self.folder resign];
}

/* Mark as read all messages in this folder.
 */
-(void)markAllRead
{
    NSAlert * alert = [[NSAlert alloc] init];
    
    [alert addButtonWithTitle:NSLocalizedString(@"Yes", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"No", nil)];
    [alert setMessageText:NSLocalizedString(@"Mark All Read", nil)];
    [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(IsTopLevelFolder(self.folder) ?
                                                                           @"Do you want to mark as read all messages in the %@ forum?" :
                                                                           @"Do you want to mark as read all messages in the %@ topic?", nil), self.name]];
    
    if ([alert runModal] == NSAlertFirstButtonReturn)
        [self.folder markAllRead];
}

/* Can mark all read if there are any unread in this folder or
 * any sub-folders.
 */
-(BOOL)canMarkAllRead
{
    return self.unread > 0;
}

/* Can always delete this folder.
 */
-(BOOL)canDelete
{
    return YES;
}

/* Return the unread count on this folder.
 */
-(NSInteger)unread
{
    if (IsTopLevelFolder(self.folder))
    {
        int unreadCount = 0;
        for (Folder * child in self.folder.children)
            unreadCount += child.unread;
        return unreadCount;
    }
    return self.folder.unread;
}

/* Return the priority unread count on this folder.
 */
-(NSInteger)unreadPriority
{
    if (IsTopLevelFolder(self.folder))
    {
        int unreadCount = 0;
        for (Folder * child in self.folder.children)
            unreadCount += child.unreadPriority;
        return unreadCount;
    }
    return self.folder.unreadPriority;
}

/* Return the folder flags.
 */
-(FolderFlags)flags
{
    return self.folder.flags;
}

/* Allow searches scoped to this folder.
 */
-(BOOL)allowsScopedSearch
{
    return !IsTopLevelFolder(self.folder);
}

/* Refresh the items returned by this folder.
 */
-(BOOL)refresh
{
    if (IsTopLevelFolder(self.folder))
    {
        [CIX.directoryCollection refreshForum:self.name];
        DirForum * forum = [CIX.directoryCollection forumByName:self.name];
        [forum refresh];

        for (Folder * child in self.folder.children)
            if ([child countOfMessages] > 0)
                [child refresh];
        return YES;
    }
    [self.folder refresh];
    return YES;
}

/* Return a collection of items in this folder
 */
-(NSArray *)items
{
    return [self.folder.messages allMessages];
}
@end
