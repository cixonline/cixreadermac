//
//  CRWordInputValidator.m
//  CIXReader
//
//  Created by Steve Palmer on 19/01/2015.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "CRWordInputValidator.h"
#import "StringExtensions.h"

@implementation CRWordInputValidator

-(NSString *)stringForObjectValue:(id)object
{
    return (NSString *)object;
}

-(BOOL)getObjectValue:(id *)object forString:(NSString *)string errorDescription:(NSString **)error
{
    *object = string;
    return YES;
}

-(BOOL)isPartialStringValid:(NSString*)partialString newEditingString:(NSString**)newString errorDescription:(NSString**)error
{
    if ([partialString length] == 0)
        return YES;
    
    if ([partialString indexOfCharacterInString:' ' afterIndex:0] != NSNotFound)
    {
        NSBeep();
        return NO;
    }
    return YES;
}
@end
