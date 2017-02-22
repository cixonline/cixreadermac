//
//  DirCategory.m
//  CIXClient
//
//  Created by Steve Palmer on 28/08/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "CIX.h"
#import "DirCategory.h"

@implementation DirCategory

/* Returns the result of comparing two categories by category name.
 */
-(NSComparisonResult)compare:(Folder *)otherObject
{
    return [self.name caseInsensitiveCompare:otherObject.name];
}

/* Call superclass to get description format
 */
-(NSString *)description
{
    return [super description];
}
@end
