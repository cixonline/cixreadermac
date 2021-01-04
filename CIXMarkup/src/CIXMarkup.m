//
//  CIXMarkup.m
//  CIXMarkup
//
//  Created by Steve Palmer on 24/06/2015.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "CIXMarkup.h"
#import "StringExtensions.h"

@implementation CIXMarkup

static int _blockQuoteDepth;


/* Convert the specified text to HTML, translating any markup codes
 */
+(NSString *)markupToHTML:(NSString *)text
{
    NSMutableString * outputString = [[NSMutableString alloc] init];
    NSArray * lines = [text componentsSeparatedByString:@"\n"];
    
    for (NSString * line in lines)
    {
        if (outputString.length > 0)
            [outputString appendString:@"<br />"];
        [outputString appendString:[self parseLine:line]];
    }

    while (_blockQuoteDepth > 0)
    {
        [outputString appendString:@"</blockquote>"];
        --_blockQuoteDepth;
    }
    
    // Optimise the result
    [outputString replaceString:@"<br /><blockquote>" withString:@"<blockquote>"];
    [outputString replaceString:@"<br /></blockquote>" withString:@"</blockquote>"];
    
    return outputString;
}

/* Return whether the specified character can indicate the start of
 * a style.
 */
+(bool)canPrecedeStyle:(char)ch withChar:(char)newCh
{
    NSMutableCharacterSet * delimiterSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"*/_"];
    
    [delimiterSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [delimiterSet removeCharactersInRange:NSMakeRange(newCh, 1)];
    
    return [delimiterSet characterIsMember:ch];
}

/* Read the potential HTML tag from line at the given index and return
 * whether it matches a subset of HTML tags that are passed through for
 * rendering as opposed to being escaped for presentation.
 */
+(bool)isLegalTag:(NSString *)line withIndex:(int)index
{
    NSUInteger endIndex = [line indexOfCharacterInString:'>' afterIndex:index];
    if (endIndex != NSNotFound && endIndex > index)
    {
        NSString * tagName = [[line substringWithRange:NSMakeRange(index, endIndex - index)] lowercaseString];
        if ([tagName hasPrefix:@"/"])
            tagName = [tagName substringFromIndex:1];
        
        NSArray * legalShortTags = @[ @"b", @"i", @"u" ];
        if ([legalShortTags containsObject:tagName])
            return YES;
        
        // Long tags have attributes separated by spaces so get the tag name as the first word
        // in the whole tag.
        endIndex = [tagName indexOfCharacterInString:' ' afterIndex:0];
        if (endIndex != NSNotFound)
            tagName = [tagName substringToIndex:endIndex];
        
        NSArray * legalLongTags = @[ @"font" ];
        return [legalLongTags containsObject:tagName];
    }
    return NO;
}

/* Look for the close tag for the specified style character. To qualify,
 * the end tag must be followed by whitespace.
 */
+(bool)hasCloseTag:(NSString *)line withIndex:(int)index tagChar:(char)ch
{
    NSUInteger endIndex = [line indexOfCharacterInString:ch afterIndex:index];
    if (endIndex != NSNotFound && endIndex > index)
    {
        if (endIndex + 1 == line.length)
            return YES;

        char chAfterTag = [line characterAtIndex:endIndex + 1];

        NSMutableCharacterSet * delimiterSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"*/_.,"];
        [delimiterSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        return [delimiterSet characterIsMember:chAfterTag];
    }
    return NO;
}

/* Parse the specified line and return its HTML equivalent.
 */
+(NSString *)parseLine:(NSString *)line
{
    NSMutableString * outputString = [[NSMutableString alloc] init];
    bool inBold = NO;
    bool inUnderline = NO;
    bool inItalic = NO;
    bool lineStart = YES;
    bool absorbTag = NO;
    int blockCount = 0;
    char lastChar = '\n';
    int index = 0;
    
    NSCharacterSet * whitespaceSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    while (index < line.length)
    {
        char ch = [line characterAtIndex:index++];
        if (absorbTag)
        {
            [outputString appendFormat:@"%c", ch];
            absorbTag = ch != '>';
            continue;
        }
        if (lineStart)
        {
            if ([whitespaceSet characterIsMember:ch])
                continue;
            if (ch == '>')
            {
                ++blockCount;
                continue;
            }
        }
        if (blockCount > _blockQuoteDepth)
            while (_blockQuoteDepth != blockCount)
            {
                [outputString appendString:@"<blockquote>"];
                ++_blockQuoteDepth;
            }
        if (blockCount < _blockQuoteDepth)
            while (_blockQuoteDepth != blockCount)
            {
                [outputString appendString:@"</blockquote>"];
                --_blockQuoteDepth;
            }
        switch (ch)
        {
            case '<':
                if ([self isLegalTag:line withIndex:index])
                {
                    [outputString appendFormat:@"%c", ch];
                    absorbTag = YES;
                }
                else
                    [outputString appendString:@"&lt;"];
                break;
            case '>':
                [outputString appendString:@"&gt;"];
                break;
            case '&':
                [outputString appendString:@"&amp;"];
                break;
            case '*':
                if (inBold)
                {
                    [outputString appendString:@"</b>"];
                    inBold = false;
                }
                else if ([self canPrecedeStyle:lastChar withChar:ch] && [self hasCloseTag:line withIndex:index tagChar:ch])
                {
                    [outputString appendString:@"<b>"];
                    inBold = true;
                }
                else
                    [outputString appendFormat:@"%c", ch];
                break;
            case '_':
                if (inUnderline)
                {
                    [outputString appendString:@"</u>"];
                    inUnderline = false;
                }
                else if ([self canPrecedeStyle:lastChar withChar:ch] && [self hasCloseTag:line withIndex:index tagChar:ch])
                {
                    [outputString appendString:@"<u>"];
                    inUnderline = true;
                }
                else
                    [outputString appendFormat:@"%c", ch];
                break;
            case '/':
                if (inItalic)
                {
                    [outputString appendString:@"</i>"];
                    inItalic = false;
                }
                else if ([self canPrecedeStyle:lastChar withChar:ch] && [self hasCloseTag:line withIndex:index tagChar:ch])
                {
                    [outputString appendString:@"<i>"];
                    inItalic = true;
                }
                else
                    [outputString appendFormat:@"%c", ch];
                break;
            default:
                [outputString appendFormat:@"%c", ch];
                break;
        }
        lineStart = false;
        lastChar = ch;
    }
    if (inBold)
        [outputString appendString:@"</b>"];
    if (inUnderline)
        [outputString appendString:@"</u>"];
    if (inItalic)
        [outputString appendString:@"</i>"];
    return outputString;
}
@end
