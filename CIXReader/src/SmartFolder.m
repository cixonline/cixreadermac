//
//  SmartFolder.m
//  CIXReader
//
//  Created by Steve Palmer on 12/11/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "SmartFolder.h"
#import "CIX.h"

static NSImage * smartFolderImage;

@implementation SmartFolder

/* Return the type of view for this folder.
 */
-(AppView)viewForFolder
{
    return AppViewTopic;
}

/* Return the unique ID of this folder. For non-topic folders,
 * this will be a negative value.
 */
-(ID_type)ID
{
    return -1;
}

/* Return the folder tree icon for this folder.
 */
-(NSImage *)icon
{
    if (smartFolderImage == nil)
        smartFolderImage = [NSImage imageNamed:@"smartFolder.tiff"];
    return smartFolderImage;
}

/* Return the folder full name
 */
-(NSString *)fullName
{
    return self.name;
}

/* Return a collection of items arranged by the specified view.
 */
-(NSArray *)items
{
    return [CIX.folderCollection messagesWithCriteria:self.criteria];
}

/* Only draft messages allowed in this folder.
 */
-(BOOL)canContain:(id)value
{
    return self.containComparator((Message *)value);
}
@end
