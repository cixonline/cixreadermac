//
//  CRImageView.m
//  CIXReader
//
//  Created by Steve Palmer on 02/11/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "CRImageView.h"

@implementation CRImageView

-(void)mouseDown:(NSEvent *)theEvent
{
    if (theEvent.type != NSEventTypeLeftMouseDown)
        [super mouseDown:theEvent];
}

-(void)mouseUp:(NSEvent *)theEvent
{
    if (theEvent.type != NSEventTypeLeftMouseUp)
        [super mouseUp:theEvent];
    else
    {
        NSPoint pt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        if (NSPointInRect(pt, self.bounds) && self.delegate != nil)
        {
            if ([(NSObject *)self.delegate respondsToSelector:self.action])
            {
                [self sendAction:self.action to:self.delegate];
            }
        }
    }
}

/* Return the 'label' associated with this imageview.
 * TODO: This is actually wrong. It needs to return the user defined label.
 */
-(NSString *)accessibilityLabel
{
    return @"CRImageView";
}

-(BOOL)accessibilityPerformPress
{
    if ([(NSObject *)self.delegate respondsToSelector:self.action])
    {
        [self sendAction:self.action to:self.delegate];
        return YES;
    }
    return NO;
}
@end
