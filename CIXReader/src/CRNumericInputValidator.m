//
//  CRNumericInputValidator.m
//  CIXReader
//
//  Created by Steve Palmer on 24/10/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "CRNumericInputValidator.h"

@implementation CRNumericInputValidator

-(BOOL)isPartialStringValid:(NSString*)partialString newEditingString:(NSString**)newString errorDescription:(NSString**)error
{
    if ([partialString length] == 0)
        return YES;
    
    NSScanner * scanner = [NSScanner scannerWithString:partialString];
    if (!([scanner scanInt:0] && [scanner isAtEnd]))
    {
        NSBeep();
        return NO;
    }
    return YES;
}
@end
