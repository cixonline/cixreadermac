//
//  ModeratorItem.m
//  CIXReader
//
//  Created by Steve Palmer on 05/10/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "ModeratorItem.h"

@implementation ModeratorItem
@end

@implementation ModeratorCollectionViewItem

/* Catch the interface to set the represented object so we can store it
 * for later de-reference when we catch an click on the image in
 * the moderator item view.
 */
-(void)setRepresentedObject:(id)object
{
    self.item = object;
    [super setRepresentedObject:object];
}
@end
