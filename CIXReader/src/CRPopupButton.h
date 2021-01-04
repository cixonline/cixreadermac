//
//  CRPopupButton.h
//  CIXReader
//
//  Created by Steve Palmer on 15/08/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "CRToolbarButton.h"

@interface CRPopupButton : CRToolbarButton {
	NSFont * _popupFont;
	BOOL _popBelow;
}

// Properties
@property (retain, atomic) NSMenu * theMenu;

// Public functions
-(NSMenu *)theMenu;
-(void)setSmallMenu:(BOOL)useSmallMenu;
-(void)setPopupBelow:(BOOL)flag;
-(void)setTheMenu:(NSMenu *)menu;
@end
