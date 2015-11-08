//
//  CRToolbarItem.m
//  CIXReader
//
//  Created by Steve Palmer on 15/08/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "CRToolbarItem.h"
#import "CRToolbarButton.h"
#import "CRPopupButton.h"

#define CenterRect(x,y) (NSMakeRect(((x).width - (y).width)/2, (((x).height - (y).height)/2), (y).width, (y).height))		

@implementation CRToolbarItem

/* validate
 * Override validate so that we pass the call to the view target. By default,
 * toolbar items which are based on views don't get any validation.
 */
-(void)validate
{
	if (![NSApp isActive])
		[self setEnabled:NO];
	else 
		[self setEnabled:YES];
	id target = [self target];
	if ([target respondsToSelector:@selector(validateToolbarItem:)])
		[self setEnabled:[target validateToolbarItem:self]];
}

/* setEnabled
 * Extends the setEnabled on the item to pass on the call to the menu attached
 * to a popup button menu item.
 */
-(void)setEnabled:(BOOL)enabled
{
	[super setEnabled:enabled];
	[[self menuFormRepresentation] setEnabled:enabled];
}

/* setView
 * Extends the setView to also set the button min/max size from the view size.
 */
-(void)setView:(NSView *)theView
{
	NSRect fRect = [theView frame];
	[super setView:theView];
	[self setMinSize:fRect.size];
	[self setMaxSize:fRect.size];
}

/* compositeButtonImage
 * Define the toolbar item as a button and initialises it with the necessary
 * attributes and states by compositing a blank button with the specified image
 * from the given folder.
 */
-(void)compositeButtonImage:(NSString *)imageName
{
	NSString * resourcePath = [[NSBundle mainBundle] resourcePath];
	NSImage * userImage = [NSImage imageNamed:imageName];
	NSSize userImageSize = [userImage size];
	NSRect userImageRect = NSMakeRect(0.0, 0.0, userImageSize.width, userImageSize.height);

	// May not necessarily be a small image in which case we'd need to synthesize one from the large one
	NSSize smallUserImageSize;
	NSRect smallUserImageRect;

    smallUserImageSize = NSMakeSize(12.0, 12.0);
    smallUserImageRect = userImageRect;

	NSImage * buttonImage = [[NSImage alloc] initWithContentsOfFile:[resourcePath stringByAppendingPathComponent:@"blankButton.tiff"]];
	NSSize buttonSize = [buttonImage size];
	[buttonImage lockFocus];
	[userImage drawInRect:CenterRect(buttonSize, userImageSize) fromRect:userImageRect operation:NSCompositeSourceOver fraction:1.0];
	[buttonImage unlockFocus];

	NSImage * pressedImage = [[NSImage alloc] initWithContentsOfFile:[resourcePath stringByAppendingPathComponent:@"blankButtonPressedBurned.tiff"]];
	buttonSize = [pressedImage size];
	[pressedImage lockFocus];
	[userImage drawInRect:CenterRect(buttonSize, userImageSize) fromRect:userImageRect operation:NSCompositeSourceOver fraction:1.0];
	[pressedImage unlockFocus];
	
	NSImage * smallNormalImage = [[NSImage alloc] initWithContentsOfFile:[resourcePath stringByAppendingPathComponent:@"blankSmallButton.tiff"]];
	buttonSize = [smallNormalImage size];
	[smallNormalImage lockFocus];
	[userImage drawInRect:CenterRect(buttonSize, smallUserImageSize) fromRect:smallUserImageRect operation:NSCompositeSourceOver fraction:1.0];
	[smallNormalImage unlockFocus];

	NSImage * smallPressedImage = [[NSImage alloc] initWithContentsOfFile:[resourcePath stringByAppendingPathComponent:@"blankSmallButtonPressed.tiff"]];
	buttonSize = [smallPressedImage size];
	[smallPressedImage lockFocus];
	[userImage drawInRect:CenterRect(buttonSize, smallUserImageSize) fromRect:smallUserImageRect operation:NSCompositeSourceOver fraction:1.0];
	[smallPressedImage unlockFocus];
	
	[self setButtonImages:buttonImage
			 pressedImage:pressedImage
		 smallNormalImage:smallNormalImage
		smallPressedImage:smallPressedImage];
}

/* setButtonImage
 * Define the toolbar item as a button and initialises it with the necessary
 * attributes and states using the specified image name.
 */
-(void)setButtonImage:(NSString *)imageName
{
	NSString * normalImage = [NSString stringWithFormat:@"%@.tiff", imageName];
	NSString * pressedImage = [NSString stringWithFormat:@"%@Pressed.tiff", imageName];
	NSString * smallNormalImage = [NSString stringWithFormat:@"%@Small.tiff", imageName];
	NSString * smallPressedImage = [NSString stringWithFormat:@"%@SmallPressed.tiff", imageName];

	[self setButtonImages:[NSImage imageNamed:normalImage]
			 pressedImage:[NSImage imageNamed:pressedImage]
		 smallNormalImage:[NSImage imageNamed:smallNormalImage]
		smallPressedImage:[NSImage imageNamed:smallPressedImage]];
}

/* setButtonImages
 * Define the toolbar item as a button and initialises it with the necessary
 * attributes and states using the specified set of images for each state.
 */
-(void)setButtonImages:(NSImage *)buttonImage pressedImage:(NSImage *)pressedImage smallNormalImage:(NSImage *)smallNormalImage smallPressedImage:(NSImage *)smallPressedImage
{
	NSSize buttonSize = [buttonImage size];
	CRToolbarButton * button = [[CRToolbarButton alloc] initWithFrame:NSMakeRect(0, 0, buttonSize.width, buttonSize.height) withItem:self];

	[button setImage:buttonImage];
	[button setAlternateImage:pressedImage];
	[button setSmallImage:smallNormalImage];
	[button setSmallAlternateImage:smallPressedImage];
	
	// Save the current target and action and reapply them afterward because assigning a view
	// causes them to be deleted.
	id currentTarget = [self target];
	SEL currentAction = [self action];
	[self setView:button];
	[self setTarget:currentTarget];
	[self setAction:currentAction];
    
    NSMenuItem *menuRep = [[NSMenuItem alloc] initWithTitle:self.label action:self.action keyEquivalent:@""];
    [menuRep setTarget:self.target];
    [self setMenuFormRepresentation:menuRep];

}

/* setPopup
 * Defines the toolbar item as a popup button and initialises it with the specified
 * images and menu.
 */
-(void)setPopup:(NSString *)imageName withMenu:(NSMenu *)theMenu
{
	NSString * normalImage = [NSString stringWithFormat:@"%@.tiff", imageName];
	NSString * pressedImage = [NSString stringWithFormat:@"%@Pressed.tiff", imageName];
	NSString * smallNormalImage = [NSString stringWithFormat:@"%@Small.tiff", imageName];
	NSString * smallPressedImage = [NSString stringWithFormat:@"%@SmallPressed.tiff", imageName];
	
	NSImage * buttonImage = [NSImage imageNamed:normalImage];
	NSSize buttonSize = [buttonImage size];
	CRPopupButton * button = [[CRPopupButton alloc] initWithFrame:NSMakeRect(0, 0, buttonSize.width, buttonSize.height) withItem:self];
	
	[button setImage:buttonImage];
	[button setAlternateImage:[NSImage imageNamed:pressedImage]];
	[button setSmallImage:[NSImage imageNamed:smallNormalImage]];
	[button setSmallAlternateImage:[NSImage imageNamed:smallPressedImage]];
	
	[self setView:button];
	
	NSMenuItem * menuItem = [[NSMenuItem alloc] init];
	[button setTheMenu:theMenu];
	[button setPopupBelow:YES];
	[menuItem setSubmenu:[button theMenu]];
	[menuItem setTitle:[self label]];
	[self setMenuFormRepresentation:menuItem];
}
@end
