//
//  CRVerticalTextCell.m
//  CIXReader
//
//  Created by Daniel Jalkut on 6/17/06.
//  Copyright 2006 Red Sweater Software. All rights reserved.
//

#import "CRVerticalTextCell.h"

@implementation CRVerticalTextCell

-(NSRect)drawingRectForBounds:(NSRect)theRect
{
	NSRect newRect = [super drawingRectForBounds:theRect];

	// When the text field is being 
	// edited or selected, we have to turn off the magic because it screws up 
	// the configuration of the field editor.  We sneak around this by 
	// intercepting selectWithFrame and editWithFrame and sneaking a 
	// reduced, centered rect in at the last minute.
	if (_isEditingOrSelecting == NO)
	{
		NSSize textSize = [self cellSizeForBounds:theRect];

		float heightDelta = newRect.size.height - textSize.height;
		if (heightDelta > 0)
		{
			newRect.size.height -= heightDelta;
			newRect.origin.y += (heightDelta / 2);
		}
	}
	
	return newRect;
}

-(void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength
{
	NSRect drawRect = [self drawingRectForBounds:aRect];
	_isEditingOrSelecting = YES;
	[super selectWithFrame:drawRect inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
	_isEditingOrSelecting = NO;
}

-(void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent
{	
	NSRect drawRect = [self drawingRectForBounds:aRect];
	_isEditingOrSelecting = YES;
	[super editWithFrame:drawRect inView:controlView editor:textObj delegate:anObject event:theEvent];
	_isEditingOrSelecting = NO;
}

@end
