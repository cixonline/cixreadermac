//
//  FolderBase.m
//  CIXReader
//
//  Created by Steve Palmer on 22/08/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "FolderBase.h"

@implementation FolderBase

/* Override
 */
-(id)representedObject
{
    return self;
}

/* Return the type of view for this folder.
 */
-(AppView)viewForFolder
{
    return AppViewWelcome;
}

/* Return the unique ID of this folder. For topic folders,
 * this will be a positive integer > 0.
 */
-(ID_type)ID
{
    return 0;
}

/* Return the folder tree icon for this folder.
 */
-(NSImage *)icon
{
    return nil;
}

/* Return the folder full name
 */
-(NSString *)fullName
{
    return self.name;
}

/* Return the address of this folder
 */
-(NSString *)address
{
    return nil;
}

/* Return the unread count on this folder.
 */
-(NSInteger)unread
{
    return 0;
}

/* Return the priority unread count on this folder.
 */
-(NSInteger)unreadPriority
{
    return 0;
}

/* Return the folder flags.
 */
-(FolderFlags)flags
{
    return 0;
}

/* Delete the folder. By default, does nothing.
 */
-(void)delete
{
}

/* By default, cannot delete this folder.
 */
-(BOOL)canDelete
{
    return NO;
}

/* Return an array of items to display in the view
 */
-(NSArray *)items
{
    return nil;
}

/* Refresh the items returned by this folder.
 */
-(BOOL)refresh
{
    return NO;
}

/* Returns the result of comparing two folders by folder name.
 */
-(NSComparisonResult)compare:(Folder *)otherObject
{
	return [[self name] caseInsensitiveCompare:[otherObject name]];
}

/* Tests whether the specified value can be contained in this
 * folder.
 */
-(BOOL)canContain:(id)value
{
    return YES;
}

/* Default implementation of markAllRead does nothing.
 */
-(void)markAllRead
{
}

/* By default, searches are global and not scoped to this folder.
 */
-(BOOL)allowsScopedSearch
{
    return NO;
}

/** Returns a description of this object.
 */
-(NSString*)description
{
    NSMutableString * text = [NSMutableString stringWithFormat:@"<%@>\n", [self class]];
    [text appendFormat:@"   [ID]: %lld\n", self.ID];
    [text appendFormat:@"   [name]: %@\n", self.name];
    [text appendFormat:@"   [unread]: %ld\n", (long)self.unread];
    [text appendFormat:@"   [address]: %@\n", self.address];
    [text appendFormat:@"   [flags]: %d\n", self.flags];
    [text appendFormat:@"</%@>", [self class]];
    return text;
}
@end
