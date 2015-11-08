//
//  CRRoundImageView.m
//  AvatarTest
//
//  Created by Peter Stuart on 4/20/13.
//  Copyright (c) 2013 Electric Peel, LLC. All rights reserved.
//

#import "CRRoundImageView.h"
#import "ImageExtensions.h"

@implementation CRRoundImageView

-(id)initWithCoder:(NSCoder *)coder
{
    if ((self = [super initWithCoder:coder]) != nil)
    {
        _blurOffset = 3;
        _blurRadius = 4;
        _circleDiameter = 50;
    }
    return self;
}

-(void)mouseEntered:(NSEvent *)theEvent
{
    _withinImage = YES;
    [self setNeedsDisplay:YES];
}

-(void)mouseExited:(NSEvent *)theEvent
{
    _withinImage = NO;
    [self setNeedsDisplay:YES];
}

-(void)updateTrackingAreas
{
    if (_trackingArea != nil) {
        [self removeTrackingArea:_trackingArea];
    }
    
    int opts = NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways;
    _trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds]
                                                 options:opts
                                                   owner:self
                                                userInfo:nil];
    [self addTrackingArea:_trackingArea];
}

-(NSEdgeInsets)alignmentRectInsets
{
    return NSEdgeInsetsMake(0, self.blurRadius, self.blurOffset + self.blurRadius, self.blurRadius);
}

-(NSSize)intrinsicContentSize
{
    return NSMakeSize(self.circleDiameter, self.circleDiameter);
}

-(void)drawRect:(NSRect)dirtyRect
{
    if (self.image != nil)
    {
        CGFloat blurRadius = self.blurRadius;
        NSSize shadowOffset = NSMakeSize(0, -self.blurOffset);
        NSImage *circularImage = [self.image maskedCircularImageWithDiameter:self.circleDiameter];
        NSSize iconSize = [circularImage size];
        
        NSRect rect = NSMakeRect(blurRadius, blurRadius + self.blurOffset, iconSize.width, iconSize.height);
        
        NSShadow *shadow = [NSShadow new];
        shadow.shadowBlurRadius = blurRadius;
        shadow.shadowOffset = shadowOffset;
        shadow.shadowColor = [NSColor blackColor];
        [shadow set];

        if (_withinImage && self.isEditable)
        {
            NSRect iconRect = NSMakeRect(0.0, 0.0, iconSize.width, iconSize.height);
            [circularImage lockFocus];
            [[NSColor colorWithCalibratedWhite:0.0 alpha:0.33] set];
            NSRectFillUsingOperation(iconRect, NSCompositeSourceAtop);
            
            NSString * editText = NSLocalizedString(@"Edit", nil);
            NSDictionary * textAttr = @{
                        NSForegroundColorAttributeName  : [NSColor whiteColor],
                        NSFontAttributeName             : [NSFont fontWithName:@"Helvetica" size:14]
                        };
            NSSize textSize = [editText sizeWithAttributes:textAttr];
            [editText drawAtPoint:NSMakePoint((iconSize.width - textSize.width) / 2, 4) withAttributes:textAttr];
            [circularImage unlockFocus];
        }
        [circularImage drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    }
}

-(void)setCircleDiameter:(CGFloat)circleDiameter
{
    _circleDiameter = circleDiameter;
    
    [self setNeedsDisplay:YES];
    [self invalidateIntrinsicContentSize];
}

-(void)setBlurRadius:(CGFloat)blurRadius
{
    _blurRadius = blurRadius;
    
    [self setNeedsDisplay:YES];
    [self invalidateIntrinsicContentSize];
}

-(void)setBlurOffset:(CGFloat)blurOffset
{
    _blurOffset = blurOffset;
    
    [self setNeedsDisplay:YES];
    [self invalidateIntrinsicContentSize];
}
@end
