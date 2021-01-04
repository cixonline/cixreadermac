//
//  PopUpButtonExtensions.m
//  CIXExtensions
//
//  Created by Steve Palmer on 10/09/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "PopUpButtonExtensions.h"

@implementation NSPopUpButton (PopUpButtonExtensions)

/* addItemWithTitle
 * Add an item to the popup button menu with an associated image. The image is rescaled to 16x16 to fit in
 * the menu. I've been trying to figure out how to get the actual menu item height but at a minimum, 16x16
 * is the conventional size for a 'small' document icon. So I'm OK with this for now.
 */
-(void)addItemWithTitle:(NSString *)title image:(NSImage *)image
{
	NSMenuItem * newItem = [[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
	[image setSize:NSMakeSize(16, 16)];
	[newItem setImage:image];
	[[self menu] addItem:newItem];
}

/* addItemWithTarget
 * Add an item to the popup button menu with the specified target.
 */
-(void)addItemWithTarget:(NSString *)title target:(SEL)target
{
	NSMenuItem * newItem = [[NSMenuItem alloc] initWithTitle:title action:target keyEquivalent:@""];
	[[self menu] addItem:newItem];
}

/* addItemWithTag
 * Add an item to the popup button menu with the specified tag.
 */
-(void)addItemWithTag:(NSString *)title tag:(int)tag
{
	NSMenuItem * newItem = [[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
	[newItem setTag:tag];
	[[self menu] addItem:newItem];
}

/* addItemWithRepresentedObject
 * Add an item to the popup button menu with the specified represented object.
 */
-(void)addItemWithRepresentedObject:(NSString *)title object:(id)object
{
	NSMenuItem * newItem = [[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
	[newItem setRepresentedObject:object];
	[[self menu] addItem:newItem];
}

/* insertItemWithTag
 * Inserts the specified menu item into the popup menu at the given index and assigns it
 * an initial tag value.
 */
-(void)insertItemWithTag:(NSString *)title tag:(int)tag atIndex:(int)index
{
	NSMenuItem * newItem = [[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
	[newItem setTag:tag];
	[[self menu] insertItem:newItem atIndex:index];
}

/* representedObjectForSelection
 * Returns the represented object associated with the selected item.
 */
-(id)representedObjectForSelection
{
	NSMenuItem * theItem = [self selectedItem];
	return [theItem representedObject];
}

/* tagForSelection
 * Returns the tag associated with the selected item.
 */
-(NSInteger)tagForSelection
{
	NSMenuItem * theItem = [self selectedItem];
	return [theItem tag];
}

/* addSeparator
 * Add a separator item to the popup button menu.
 */
-(void)addSeparator
{
	[[self menu] addItem:[NSMenuItem separatorItem]];
}
@end
