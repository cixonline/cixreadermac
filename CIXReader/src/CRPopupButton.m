//
//  CRPopupButton.m
//  CIXReader
//
//  Created by Steve Palmer on 15/08/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "CRPopupButton.h"

@implementation CRPopupButton

/* Initialises a simple subclass of NSButton that pops up a menu
 * if one is associated with it.
 */
-(id)initWithFrame:(NSRect)frameRect withItem:(NSToolbarItem *)theItem
{
	if ((self = [super initWithFrame:frameRect withItem:theItem]) != nil)
	{
		_popBelow = NO;
		_popupFont = [NSFont menuFontOfSize:0];
	}
	return self;
}

/* Sets whether the menu pops up above or below the button.
 */
-(void)setPopupBelow:(BOOL)flag
{
	_popBelow = flag;
}

/* Specifies that the popup menu should use a small font.
 */
-(void)setSmallMenu:(BOOL)useSmallMenu
{
	_popupFont = [NSFont menuFontOfSize:(useSmallMenu ? 12 : 0)];
	_popBelow = YES;
}

/* Handle the mouse down event over the button. If we have a menu associated with
 * ourselves, pop up the menu above the button.
 */
-(void)mouseDown:(NSEvent *)theEvent
{
	if ([self isEnabled] && self.theMenu != nil)
	{
		[self highlight:YES];
		NSPoint popPoint = NSMakePoint([self bounds].origin.x, [self bounds].origin.y);
		if (_popBelow)
			popPoint.y += [self bounds].size.height + 5;
        NSEvent * evt = [NSEvent mouseEventWithType:[theEvent type]
								 location:[self convertPoint:popPoint toView:nil]
							modifierFlags:[theEvent modifierFlags]
								timestamp:[theEvent timestamp]
							 windowNumber:[theEvent windowNumber]
								  context:[theEvent context]
							  eventNumber:[theEvent eventNumber]
							   clickCount:[theEvent clickCount]
								 pressure:[theEvent pressure]];
		[NSMenu popUpContextMenu:self.theMenu withEvent:evt forView:self withFont:_popupFont];
		[self highlight:NO];
	}
}

/* Handle the mouse up event over the button.
 */
-(void)mouseUp:(NSEvent *)theEvent
{
	if ([self isEnabled])
		[self highlight:NO];
}
@end
