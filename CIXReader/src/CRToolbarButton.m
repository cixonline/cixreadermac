//
//  CRToolbarButton.m
//  CIXReader
//
//  Created by Steve Palmer on 15/08/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "CRToolbarButton.h"

@implementation CRToolbarButton

/* initWithFrame
 * Initialise a ToolbarButton item. This is a subclass of a toolbar button
 * that responds properly to sizing requests from the toolbar.
 */
-(id)initWithFrame:(NSRect)frameRect withItem:(NSToolbarItem *)tbItem
{
	if ((self = [super initWithFrame:frameRect]) != nil)
	{
		_item = tbItem;
		_image = nil;
		_alternateImage = nil;
		_smallImage = nil;
		_smallAlternateImage = nil;
		_imageSize = NSMakeSize(32.0, 32.0);
		_smallImageSize = NSMakeSize(24.0, 24.0);

		// Our toolbar buttons have specific attributes to make them
		// behave like toolbar buttons.
		[self setButtonType:NSMomentaryChangeButton];
		[self setBordered:NO];
		[self setBezelStyle:NSSmallSquareBezelStyle];
		[self setImagePosition:NSImageOnly];
	}
	return self;
}

/* itemIdentifier
 * Return the button's item identifier.
 */
-(NSString *)itemIdentifier
{
	return [_item itemIdentifier];
}

/* setSmallImage
 * Set the image displayed when the button is made small.
 */
-(void)setSmallImage:(NSImage *)newImage
{
	_smallImage = newImage;
	if (_smallImage != nil)
		_smallImageSize = [_smallImage size];
}

/* setSmallAlternateImage
 * Set the alternate image for when the button is made small.
 */
-(void)setSmallAlternateImage:(NSImage *)newImage
{
	_smallAlternateImage = newImage;
}

/* setImage
 * Override the setImage on the NSButton so we can cache the image and button size
 * and return the right size in setControlSize. Also call setScalesWhenResized
 * so we scale the image for small buttons if no alternatives are provided.
 */
-(void)setImage:(NSImage *)newImage
{
	_image = newImage;

	[super setImage:_image];
	if (_image != nil)
		_imageSize = [_image size];
}

/* setAlternateImage
 * Override the setAlternateImage on the NSButton and call setScalesWhenResized
 * on the image so if we don't implement our own small images then we scale
 * properly.
 */
-(void)setAlternateImage:(NSImage *)newImage
{
	_alternateImage = newImage;
	
	[super setAlternateImage:_alternateImage];
}

/* controlSize
 * Return the control size. This must be implemented.
 */
-(NSControlSize)controlSize
{
	return [[self cell] controlSize];
}

/* setControlSize
 * Called by the toolbar control when the user changes the toolbar size.
 * We use this to adjust the button image.
 */
-(void)setControlSize:(NSControlSize)size
{
	NSSize s;

    if (size == NSControlSizeRegular)
	{
		// When switching to regular size, if we have small versions then we
		// can assume that we're switching from those small versions. So we
		// need to replace the button image.
		if (_image)
			[super setImage:_image];
		if (_alternateImage)
			[super setAlternateImage:_alternateImage];
		s = _imageSize;
	}
	else
	{
		// When switching to small size, use the small size images if they were
		// provided. Otherwise the button will scale the image down for us.
		if (_smallImage == nil)
		{
			NSImage * scaledDownImage = [_image copy];
			// Small size is about 3/4 the size of the regular image or
			// generally 24x24.
			[scaledDownImage setSize:NSMakeSize(_imageSize.width * 0.80, _imageSize.height * 0.80)];
			[self setSmallImage:scaledDownImage];
		}
		if (_smallAlternateImage == nil)
		{
			NSImage * scaledDownAlternateImage = [_alternateImage copy];
			// Small size is about 3/4 the size of the regular image or
			// generally 24x24.
			[scaledDownAlternateImage setSize:NSMakeSize(_imageSize.width * 0.80, _imageSize.height * 0.80)];
			[self setSmallAlternateImage:scaledDownAlternateImage];
		}
		[super setImage:_smallImage];
		[super setAlternateImage:_smallAlternateImage];
		s = _smallImageSize;
	}

	[_item setMinSize:s];
	[_item setMaxSize:s];
}
@end
