//
//  CRTableView.m
//  CIXReader
//
//  Created by Steve Palmer on 03/11/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "CRTableView.h"

@implementation CRTableView

/* Here is where we handle special keys when the message list view
 * has the focus so we can do custom things.
 */
-(void)keyDown:(NSEvent *)theEvent
{
    if ([[theEvent characters] length] == 1)
    {
        if ([self delegate] && [[self delegate] respondsToSelector:@selector(tableView:handleKeyDown:withFlags:)])
        {
            unichar keyChar = [[theEvent characters] characterAtIndex:0];
            if ([(id)[self delegate] tableView:self handleKeyDown:keyChar withFlags:[theEvent modifierFlags]])
                return;
        }
    }
    [super keyDown:theEvent];
}

-(void)deselectAll:(id)sender
{
    self.searchRow = -1;
    [super deselectAll:sender];
}

/** setSelectedRow
 
 Set the selection in the NSTableView to the selected row and also update the search
 index to match.
 
 @param row The row to select.
 */
-(void)setSelectedRow:(NSInteger)row
{
    self.searchRow = row;
    if (row >= 0)
    {
        [self selectRowIndexes:[[NSIndexSet alloc] initWithIndex:row] byExtendingSelection:NO];

        NSRect rowRect = [self rectOfRow:row];
        NSRect viewRect = [[self superview] frame];
        NSPoint scrollOrigin = rowRect.origin;
        scrollOrigin.y = scrollOrigin.y + (rowRect.size.height - viewRect.size.height) / 2;
        if (scrollOrigin.y < 0)
            scrollOrigin.y = 0;
        [[self superview] setBoundsOrigin:scrollOrigin];
    }
}
@end
