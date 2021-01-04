//
//  SearchFolder.m
//  CIXReader
//
//  Created by Steve Palmer on 19/11/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "SearchFolder.h"
#import "StringExtensions.h"

static NSImage * searchFolderImage;

@implementation SearchFolder

/* Return the folder tree icon for this folder.
 */
-(NSImage *)icon
{
    if (searchFolderImage == nil)
        searchFolderImage = [NSImage imageNamed:@"searchFolder.tiff"];
    return searchFolderImage;
}

/* Return the folder name.
 */
-(NSString *)name
{
    return NSLocalizedString(@"Search Results", nil);
}

/* Return a SQL criteria string for this folder based on the current
 * search string.
 */
-(NSString *)criteria
{
    return [NSString stringWithFormat:@"Body like '%%%@%%'", [self.searchString safeQuotes]];
}

/* Return the folder display name.
 */
-(NSString *)displayName
{
    return self.name;
}
@end
