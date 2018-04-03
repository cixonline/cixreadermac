//
//  CRFolderView.m
//  CIXReader
//
//  Created by Steve Palmer on 20/08/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "CRFolderView.h"

@implementation CRFolderView

/* Our initialisation.
 */
-(id)init
{
	if ((self = [super init]) != nil)
		_useTooltips = NO;
	return self;
}

/* Our init.
 */
-(void)awakeFromNib
{
	// Add the notifications for collapse and expand.
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(outlineViewItemDidExpand:) name:NSOutlineViewItemDidExpandNotification object:(id)self];
	[nc addObserver:self selector:@selector(outlineViewItemDidCollapse:) name:NSOutlineViewItemDidCollapseNotification object:(id)self];
}

/* Let the control know the expected behaviour for local and external drags.
 */
- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context
{
    switch (context)
    {
        case NSDraggingContextOutsideApplication:
            return NSDragOperationCopy;
            
        case NSDraggingContextWithinApplication:
        default:
            return NSDragOperationMove|NSDragOperationGeneric;
            break;
    }
}

/* Sets whether or not the outline view uses tooltips.
 */
-(void)setEnableTooltips:(BOOL)flag
{
	_useTooltips = flag;
	[self buildTooltips];
}

/* Create the tooltip rectangles each time the control contents change.
 */
-(void)buildTooltips
{
	NSRange range;
	NSUInteger  index;

	[self removeAllToolTips];

	// If not using tooltips or the data source doesn't implement tooltipForItem,
	// then exit now.
	if (!_useTooltips || ![_dataSource respondsToSelector:@selector(outlineView:tooltipForItem:)])
		return;

	range = [self rowsInRect:[self visibleRect]];
	for (index = range.location; index < NSMaxRange(range); index++)
	{
		NSString *tooltip;
		id item;

		item = [self itemAtRow:index];
		tooltip = [_dataSource outlineView:self tooltipForItem:item];
		if (tooltip)
			[self addToolTipRect:[self rectOfRow:index] owner:self userData:NULL];
	}
}

/* Callback function from the view to request the actual tooltip string.
 */
-(NSString *)view:(NSView *)view stringForToolTip:(NSToolTipTag)tag point:(NSPoint)point userData:(void *)data
{
	NSInteger row;

	row = [self rowAtPoint:point];
	return [_dataSource outlineView:self tooltipForItem:[self itemAtRow:row]];
}

/* Called when the view scrolls. All the tooltip rectangles need to be recomputed.
 */
-(void)resetCursorRects
{
	[self buildTooltips];
}

/* We catch this to trigger a drag completion call to the delegate so that stuff that we can't
 * do from within acceptDrop can be deferred, such as rebuilding the outlineview underneath it!
 */
-(BOOL)shouldCollapseAutoExpandedItemsForDeposited:(BOOL)deposited
{
    if ([self delegate] && [[self delegate] respondsToSelector:@selector(outlineView:dragCompleted:)])
        [(id)[self delegate] outlineView:self dragCompleted:deposited];
    return YES;
}

/* Called when the data source changes. Since we rely on the data source to provide the
 * tooltip strings, we have to rebuild the tooltips using the new source.
 */
-(void)setDataSource:(id)aSource
{
	[super setDataSource:aSource];
	[self buildTooltips];
}

/* Called when the user reloads the view data. Again, the tooltips need to be recomputed
 * using the new data.
 */
-(void)reloadData
{
	[super reloadData];
	[self buildTooltips];
}

/* Called by the user to tell the view to re-request data. Again, this could mean the
 * contents changing => tooltips change.
 */
-(void)noteNumberOfRowsChanged
{
	[super noteNumberOfRowsChanged];
	[self buildTooltips];
}

/* Our own notification when the user expanded a node. Guess what we need to
 * do here?
 */
-(void)outlineViewItemDidExpand:(NSNotification *)notification
{
	// Rebuild the tooltips if required.
	if (_useTooltips)
		[self buildTooltips];
}

/* If I have to explain it to you now, go back to the top of this source file
 * and re-read the comments.
 */
-(void)outlineViewItemDidCollapse:(NSNotification *)notification
{
	// Rebuild the tooltips if required.
	if (_useTooltips)
		[self buildTooltips];
}

/* Handle menu by moving the selection.
 */
-(NSMenu *)menuForEvent:(NSEvent *)theEvent
{
    if ([self delegate] && [[self delegate] respondsToSelector:@selector(outlineView:menuWillAppear:)])
        [(id)[self delegate] outlineView:self menuWillAppear:theEvent];
    return [self menu];
}
@end
