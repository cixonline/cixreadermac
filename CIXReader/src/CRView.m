//
//  CRView.m
//  CIXReader
//
//  Created by Steve Palmer on 03/11/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "CRView.h"

@implementation CRView

/* Make sure we get keystrokes.
 */
-(BOOL)acceptsFirstResponder
{
    return YES;
}

/* Here is where we handle special keys when the message list view
 * has the focus so we can do custom things.
 */
-(void)keyDown:(NSEvent *)theEvent
{
    if ([[theEvent characters] length] == 1)
    {
        if ([self delegate] && [[self delegate] respondsToSelector:@selector(handleKeyDown:withFlags:)])
        {
            unichar keyChar = [[theEvent characters] characterAtIndex:0];
            if ([(id)_delegate handleKeyDown:keyChar withFlags:[theEvent modifierFlags]])
                return;
        }
    }
    [super keyDown:theEvent];
}
@end
