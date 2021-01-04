//
//  CRToolbarItem.h
//  CIXReader
//
//  Created by Steve Palmer on 15/08/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

@interface CRToolbarItem : NSToolbarItem

// Public overrides
-(void)validate;
-(void)setEnabled:(BOOL)enabled;
-(void)setView:(NSView *)theView;

// New functions
-(void)setButtonImage:(NSString *)imageName;
-(void)compositeButtonImage:(NSString *)imageName;
@end
