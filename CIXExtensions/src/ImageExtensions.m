//
//  ImageExtensions.m
//  CIXExtensions
//
//  Created by Steve Palmer on 10/09/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "ImageExtensions.h"

@implementation ImageClass (ImageExtensions)

/* Returns jpeg file interchange format encoded data for an NSImage regardless of the
 * original NSImage encoding format.  compressionValue is between 0 and 1.
 * values 0.6 thru 0.7 are fine for most purposes.
 */
-(NSData *)JFIFData:(float)compressionValue
{
	NSBitmapImageRep * myBitmapImageRep = [NSBitmapImageRep imageRepWithData: [self TIFFRepresentation]];
    NSDictionary * propertyDict = @{ NSImageCompressionFactor : @(compressionValue) };
	return [myBitmapImageRep representationUsingType: NSJPEGFileType properties:propertyDict];
}

/* Constrain the image to the maximum width.
 */
-(ImageClass *)constrain:(int)maxWidth
{
    ImageClass * newImage = self;
    if (self.size.width > maxWidth)
    {
        float prop = (100 / self.size.width) * maxWidth;
        int newHeight = (prop / 100) * self.size.height;
        newImage = [self resize:NSMakeSize(maxWidth, newHeight)];
    }
    return newImage;
}

/* Return a copy of the image resized to the requested dimensions.
 */
-(ImageClass *)resize:(CGSize)newSize
{
    ImageClass * smallImage;
    
    if ([self isValid])
    {
        NSRect destRect = CGRectMake(0, 0, newSize.width, newSize.height);
        NSRect sourceRect;

        if (self.size.width > self.size.height)
        {
            int xOffset = (self.size.width - self.size.height) / 2;
            sourceRect = CGRectMake(xOffset, 0, self.size.height, self.size.height);
        }
        else if (self.size.width < self.size.height)
        {
            int yOffset = (self.size.height - self.size.width) / 2;
            sourceRect = CGRectMake(0, yOffset, self.size.width, self.size.width);
        }
        else
            sourceRect = CGRectMake(0, 0, self.size.width, self.size.height);
        
        NSImageRep * sourceImageRep = [self bestRepresentationForRect:destRect context:nil hints:nil];
        
        smallImage = [[ImageClass alloc] initWithSize: newSize];
        [smallImage lockFocus];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        [sourceImageRep drawInRect:destRect fromRect:sourceRect operation:NSCompositeCopy fraction:1.0 respectFlipped:NO hints:nil];
        [smallImage unlockFocus];
    }
    return smallImage;
}

-(ImageClass *)maskedCircularImageWithDiameter:(CGFloat)diameter
{
    NSImage * maskedImage = nil;
    if ([self isValid])
    {
        NSBitmapImageRep *representation = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                                                    pixelsWide:diameter
                                                                                    pixelsHigh:diameter
                                                                                 bitsPerSample:8
                                                                               samplesPerPixel:4
                                                                                      hasAlpha:YES
                                                                                      isPlanar:NO
                                                                                colorSpaceName:NSDeviceRGBColorSpace
                                                                                  bitmapFormat:NSAlphaFirstBitmapFormat
                                                                                   bytesPerRow:0
                                                                                  bitsPerPixel:0];
        NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:representation];
        
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:context];
        
        NSRect sourceRect = NSMakeRect(0, 0, self.size.width, self.size.height);
        NSRect destinationRect = NSMakeRect(0, 0, diameter, diameter);
        
        NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:destinationRect];
        
        [path addClip];
        
        [self drawInRect:destinationRect fromRect:sourceRect operation:NSCompositeSourceOver fraction:1.0];
        
        [NSGraphicsContext restoreGraphicsState];
        
        maskedImage = [[NSImage alloc] initWithSize:NSMakeSize(diameter, diameter)];
        [maskedImage addRepresentation:representation];
    }
    return maskedImage;
}
@end
