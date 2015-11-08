//
//  PopUpButtonExtensions.h
//  CIXExtensions
//
//  Created by Steve Palmer on 10/09/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

@interface NSPopUpButton (PopUpButtonExtensions)
	-(void)addItemWithTitle:(NSString *)title image:(NSImage *)image;
	-(void)addItemWithTarget:(NSString *)title target:(SEL)target;
	-(void)addItemWithTag:(NSString *)title tag:(int)tag;
	-(void)addItemWithRepresentedObject:(NSString *)title object:(id)object;
	-(void)insertItemWithTag:(NSString *)title tag:(int)tag atIndex:(int)index;
	-(id)representedObjectForSelection;
	-(NSInteger)tagForSelection;
	-(void)addSeparator;
@end
