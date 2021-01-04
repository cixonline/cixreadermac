//
//  ButtonExtensions.m
//  CIXExtensions
//
//  Created by Steve Palmer on 10/09/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "ButtonExtensions.h"

@implementation NSButton (ButtonExtensions)

-(void)setTitle:(NSString *)title withColor:(NSColor *)color
{
    NSMutableParagraphStyle * style = [[NSMutableParagraphStyle alloc] init];
    [style setAlignment:NSTextAlignmentCenter];
    NSDictionary * attrsDictionary = @{
                                       NSForegroundColorAttributeName  : color,
                                       NSParagraphStyleAttributeName   : @""
                                       };
    NSAttributedString * attrString = [[NSAttributedString alloc] initWithString:title attributes:attrsDictionary];
    [self setAttributedTitle:attrString];
}
@end
