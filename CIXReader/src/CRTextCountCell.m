//
//  CRTextCountCell.m
//  CIXReader
//
//  Created by Steve Palmer on 26/08/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "CRTextCountCell.h"

@implementation CRTextCountCell

@synthesize button = _button;

-(void)awakeFromNib
{
    [self setButtonStyle:NSInlineBezelStyle];
}

-(void)setButtonStyle:(NSBezelStyle)style
{
    [[self.button cell] setBezelStyle:style];
}
@end
