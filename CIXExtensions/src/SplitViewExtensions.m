//
//  SplitViewExtensions.m
//  CIXExtensions
//
//  Created by Steve on 6/15/05.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "SplitViewExtensions.h"

/* Code borrowed from http://www.cocoadev.com/index.pl?SavingNSSplitViewPosition
 * but I don't see any author associated so I'm unable to credit. Feel free to
 * edit and accredit as appropriate.
 */

@implementation NSSplitView (SplitViewExtensions)

/* Returns an NSArray of the splitview view rectangles.
 */
-(NSArray *)viewRects
{
	NSMutableArray * viewRects = [NSMutableArray array];
	NSRect frame;
	
	for (NSView * view in [self subviews])
	{
		if ([self isSubviewCollapsed:view])
			frame = NSZeroRect;
		else
			frame = [view frame];
		[viewRects addObject:NSStringFromRect(frame)];
	}
	return viewRects;
}

/* Sets the splitview view rectangles from the specified array
 */
-(void)setViewRects:(NSArray *)viewRects
{
	NSArray * views = [self subviews];
	NSInteger i, count;
	NSRect frame;

	count = MIN([viewRects count], [views count]);
	for (i = 0; i < count; i++)
	{
		frame = NSRectFromString(viewRects[i]);
		if (NSIsEmptyRect(frame))
		{
			frame = ((NSView *)views[i]).frame;
			if( [self isVertical] )
				frame.size.width = 0;
			else
				frame.size.height = 0;
		}
		((NSView *)views[i]).frame = frame;
	}
    [self adjustSubviews];
    [self layout];
}
@end
