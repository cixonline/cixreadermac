//
//  CRTextCountCell.h
//  CIXReader
//
//  Created by Steve Palmer on 26/08/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "CRButton.h"

@interface CRTextCountCell : NSTableCellView {
@private
    CRButton * _button;
}

@property(retain) IBOutlet CRButton *button;

@property(retain, readwrite) id item;

// Accessors
-(void)setButtonStyle:(NSBezelStyle)style;
@end
