//
//  CRLinkedTextField.m
//  CIXReader
//
//  Created by Steve Palmer on 31/10/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "CRLinkedTextField.h"

@implementation CRLinkedTextField

-(void)finishInitialization
{
    [self setBordered:NO];
    [self setBezeled:NO];
    [self setDrawsBackground:NO];
    [self setEditable:NO];
    [self setSelectable:NO];
    [self setEnabled:YES];
    [self setTextColor:[NSColor alternateSelectedControlColor]];
}

-(id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super initWithCoder:decoder])
        [self finishInitialization];

    return self;
}

-(id)initWithFrame:(NSRect)frame
{
    if (self = [super initWithFrame:frame])
        [self finishInitialization];

    return self;
}

-(void)mouseDown:(NSEvent *)event
{
    BOOL mouseInside = YES;
    BOOL beingClicked = YES;
    
    NSEvent * nextEvent = [[self window] nextEventMatchingMask:(NSLeftMouseUpMask | NSLeftMouseDraggedMask)];
    while (beingClicked && nextEvent != nil)
    {
        NSEventType type = [nextEvent type];
        NSPoint location = [nextEvent locationInWindow];
        
        location = [self convertPoint:location fromView:nil];
        mouseInside = NSPointInRect(location, [self bounds]);
        
        if (type == NSLeftMouseUp)
            beingClicked = NO;

        nextEvent = [[self window] nextEventMatchingMask:(NSLeftMouseUpMask | NSLeftMouseDraggedMask)];
    }
    
    if (mouseInside)
        [self sendAction:[self action] to:[self target]];
}

-(BOOL)accessibilityPerformPress
{
    [self sendAction:[self action] to:[self target]];
    return YES;
}
@end
