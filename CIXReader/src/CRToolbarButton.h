//
//  CRToolbarButton.h
//  CIXReader
//
//  Created by Steve Palmer on 15/08/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

@interface CRToolbarButton : NSButton {
	NSToolbarItem * _item;
	NSImage * _image;
	NSImage * _alternateImage;
	NSImage * _smallImage;
	NSImage * _smallAlternateImage;
	NSSize _imageSize;
	NSSize _smallImageSize;
}

// Public functions
-(NSString *)itemIdentifier;
-(id)initWithFrame:(NSRect)frameRect withItem:(NSToolbarItem *)tbItem;
-(void)setSmallImage:(NSImage *)image;
-(void)setSmallAlternateImage:(NSImage *)image;
@end
