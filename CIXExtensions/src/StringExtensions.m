//
//  StringExtensions.m
//  CIXExtensions
//
//  Created by Steve Palmer on 31/07/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "StringExtensions.h"

void dummy() {} // Needed to ensure the static library compiles

@implementation NSAttributedString (AttributedStringExtensions)

+(NSAttributedString *)stringFromHTMLString:(NSString *)string
{
    NSData * htmlText = [string dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary * options = @{
                NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)
                };
    return [[NSAttributedString alloc] initWithHTML:htmlText options:options documentAttributes:nil];
}

@end

@implementation NSMutableString (MutableStringExtensions)

/* Replaces one string with another. This is just a simpler version of the standard
 * NSMutableString replaceOccurrencesOfString function with NSLiteralString implied
 * and the range set to the entire string.
 */
-(void)replaceString:(NSString *)source withString:(NSString *)dest
{
    [self replaceOccurrencesOfString:source withString:dest options:NSLiteralSearch range:NSMakeRange(0, [self length])];
}

@end

@implementation NSString (StringExtensions)

/* Scan the specified string and convert HTML literal characters to their entity equivalents.
 */
-(NSString *)quoteAttributes
{
    NSMutableString * newString = [NSMutableString stringWithString:self];
    [newString replaceString:@"&" withString:@"&amp;"];
    [newString replaceString:@"<" withString:@"&lt;"];
    [newString replaceString:@">" withString:@"&gt;"];
    [newString replaceString:@"\"" withString:@"&quot;"];
    [newString replaceString:@"'" withString:@"&apos;"];
    return newString;
}

/* Scan the specified string and convert entities back to their
 * literal characters.
 */
-(NSString *)unquoteAttributes
{
    NSMutableString * newString = [NSMutableString stringWithString:self];
    [newString replaceString:@"&lt;" withString:@"<"];
    [newString replaceString:@"&gt;" withString:@">"];
    [newString replaceString:@"&quot;" withString:@"\""];
    [newString replaceString:@"&apos;" withString:@"'"];
    [newString replaceString:@"&amp;" withString:@"&"];
    return newString;
}

/** Unescape Unicode sequences in a string
 
 This method converts any Unicode sequences in the string to their literal
 characters. Unicode sequences are sequences of characters that begin with the
 \u escape and are followed by up to 4 digits representing a single Unicode
 character.
 
 @return The string with all Unicode sequences converted
 */
-(NSString *)unescapeUnicode
{
    NSString *convertedString = [self mutableCopy];
    
    CFStringRef transform = CFSTR("Any-Hex/Java");
    CFStringTransform((__bridge CFMutableStringRef)convertedString, NULL, transform, YES);
    
    return convertedString;
}

/* Return a path with the extension changed
 */
-(NSString *)stringByChangingPathExtension:(NSString *)ext
{
    return [[self stringByDeletingPathExtension] stringByAppendingPathExtension:ext];
}

/* trim
 * Removes leading and trailing whitespace from the string.
 */
-(NSString *)trim
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

/* trimWithCharacter
 * Removes leading and trailing characters from the string.
 */
-(NSString *)trimWithCharacter:(char)characterToTrim
{
    NSRange range;
    NSCharacterSet * singleCharacterSet;
    
    range.location = characterToTrim;
    range.length = 1;
    singleCharacterSet = [NSCharacterSet characterSetWithRange:range];
    return [self stringByTrimmingCharactersInSet:singleCharacterSet];
}

/* Determines whether the consists of just numeric characters.
 */
-(BOOL)isNumeric
{
    NSUInteger indexOfChr = 0;
    NSUInteger length = [self length];
    
    NSCharacterSet * numericSet = [NSCharacterSet decimalDigitCharacterSet];
    
    while (indexOfChr < length)
    {
        unichar ch = [self characterAtIndex:indexOfChr];
        if (![numericSet characterIsMember:ch])
            return NO;
        ++indexOfChr;
    }
    return YES;
}

/* Returns YES if the string is blank. No otherwise. A blank string is defined
 * as one comprising entirely one or more combination of spaces, tabs or newlines.
 */
-(BOOL)isBlank
{
    return [[self trim] length] == 0;
}

-(NSString *)truncateByWordWithLimit:(NSInteger)limit
{
    NSRange r = NSMakeRange(0, self.length);
    while (r.length > limit)
    {
        NSRange r0 = [self rangeOfString:@" " options:NSBackwardsSearch range:r];
        if (!r0.length) break;
        r = NSMakeRange(0, r0.location);
    }
    if (r.length == self.length)
        return self;
    return [[self substringWithRange:r] stringByAppendingString:@"..."];
}

/* Returns the first line of the string that isn't entirely spaces or tabs. If all lines in the string are
 * empty, we return an empty string.
 */
-(NSString *)firstNonBlankLine
{
    BOOL hasNonEmptyChars = NO;
    NSUInteger indexOfFirstChr = 0;
    NSUInteger indexOfLastChr = 0;
    
    NSUInteger indexOfChr = 0;
    NSUInteger length = [self length];
    while (indexOfChr < length)
    {
        unichar ch = [self characterAtIndex:indexOfChr];
        if (ch == '\r' || ch == '\n')
        {
            if (hasNonEmptyChars)
                break;
        }
        else
        {
            if (ch != ' ' && ch != '\t')
            {
                if (!hasNonEmptyChars)
                {
                    hasNonEmptyChars = YES;
                    indexOfFirstChr = indexOfChr;
                }
                indexOfLastChr = indexOfChr;
            }
        }
        ++indexOfChr;
    }
    return hasNonEmptyChars ? [self substringWithRange:NSMakeRange(indexOfFirstChr, 1u + (indexOfLastChr - indexOfFirstChr))] : @"";
}

/* Returns the index of the first occurrence of any of the specified characters in charString
 * at or after the starting index. If no occurrence is found, returns NSNotFound.
 */
-(NSUInteger)indexOfCharactersInString:(NSString *)charString afterIndex:(NSUInteger)startIndex
{
    NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:charString];
    NSUInteger length = [self length];
    NSUInteger index;
    
    if (startIndex < length)
        for (index = startIndex; index < length; ++index)
        {
            if ([charSet characterIsMember:[self characterAtIndex:index]])
                return index;
        }
    return NSNotFound;
}

/* Returns the index of the first occurrence of the specified character at or after
 * the starting index. If no occurrence is found, returns NSNotFound.
 */
-(NSUInteger)indexOfCharacterInString:(char)ch afterIndex:(NSUInteger)startIndex
{
    NSUInteger length = [self length];
    NSUInteger index;
    
    if (startIndex < length)
        for (index = startIndex; index < length; ++index)
        {
            if ([self characterAtIndex:index] == ch)
                return index;
        }
    return NSNotFound;
}

/** Convert a .NET JSON date to an NSDate

 This method accepts a JSON date string in the format /Date(xxxxxxxxxxxxx-xxxx)/ as
 returned from a .NET webservice and converts it to the corresponding NSDate object.
 
 @return An NSDate containing the specified date or nil if there was an error
 */
-(NSDate *)fromJSONDate
{
    static NSRegularExpression *dateRegEx = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateRegEx = [[NSRegularExpression alloc] initWithPattern:@"^\\/date\\((-?\\d++)(?:([+-])(\\d{2})(\\d{2}))?\\)\\/$" options:NSRegularExpressionCaseInsensitive error:nil];
    });
    NSTextCheckingResult *regexResult = [dateRegEx firstMatchInString:self options:0 range:NSMakeRange(0, [self length])];
    if (regexResult)
    {
        NSTimeInterval seconds = [[self substringWithRange:[regexResult rangeAtIndex:1]] doubleValue] / 1000.0;
        if ([regexResult rangeAtIndex:2].location != NSNotFound)
        {
            NSString *sign = [self substringWithRange:[regexResult rangeAtIndex:2]];
            seconds += [[NSString stringWithFormat:@"%@%@", sign, [self substringWithRange:[regexResult rangeAtIndex:3]]] doubleValue] * 60.0 * 60.0;
            seconds += [[NSString stringWithFormat:@"%@%@", sign, [self substringWithRange:[regexResult rangeAtIndex:4]]] doubleValue] * 60.0;
        }
        return [NSDate dateWithTimeIntervalSince1970:seconds];
    }
    return nil;
}

/** Convert a JSON string to an NSString
 
 @return An NSString with unicode and escape sequences resolved
 */
-(NSString *)fromJSONString
{
    NSMutableString * result = [NSMutableString stringWithString:[self unescapeUnicode]];
    static NSString * const ESCAPABLE_CHARS = @"/\\`*_{}[]()#+-.!>";
    
    NSCharacterSet *escapableChars = [NSCharacterSet characterSetWithCharactersInString:ESCAPABLE_CHARS];
    
    NSRange searchRange = NSMakeRange(0, result.length);
    while (searchRange.length > 0)
    {
        NSRange range = [result rangeOfString:@"\\" options:0 range:searchRange];
        
        if (range.location == NSNotFound || NSMaxRange(range) == NSMaxRange(searchRange))
            break;
        
        // If it is escapable, than remove the backslash
        unichar nextChar = [result characterAtIndex:range.location + 1];
        if ([escapableChars characterIsMember:nextChar])
        {
            [result replaceCharactersInRange:range withString:@""];
        }
        
        searchRange.location = range.location + 1;
        searchRange.length   = result.length - searchRange.location;
    }
    
    return result;
}

/** Return this string with all lines quoted.
 
 @return An NSString with lines quoted.
 */
-(NSString *)quotedString
{
    NSMutableString * quotedText = [[NSMutableString alloc] init];
    NSString * text = self;
    
    const int wrapColumn = 74;
    
    int lastSpaceIndex = -1;
    int lastSpaceColumnIndex = 0;
    int columnIndex = 0;
    int startIndex = 0;
    int currentIndex = 0;
    
    while (currentIndex < text.length)
    {
        char ch = [text characterAtIndex:currentIndex++];
        if (ch == ' ')
        {
            lastSpaceIndex = currentIndex;
            lastSpaceColumnIndex = columnIndex;
            
            ++columnIndex;
        }
        else if (ch == '\r' || ch == '\n')
        {
            [quotedText appendFormat:@"> %@\r\n", [text substringWithRange:NSMakeRange(startIndex, columnIndex)]];
            while (currentIndex < text.length && [text characterAtIndex:currentIndex] == ' ')
                ++currentIndex;
            
            startIndex = currentIndex;
            columnIndex = 0;
        }
        else if (columnIndex >= wrapColumn)
        {
            if (lastSpaceIndex == -1) // Line with no spaces!
            {
                lastSpaceIndex = currentIndex;
                lastSpaceColumnIndex = columnIndex;
            }
            
            [quotedText appendFormat:@"> %@\r\n", [text substringWithRange:NSMakeRange(startIndex, lastSpaceColumnIndex + 1)]];
            while (currentIndex < text.length && [text characterAtIndex:lastSpaceIndex] == ' ')
                ++lastSpaceIndex;
            
            currentIndex = lastSpaceIndex;
            startIndex = currentIndex;
            lastSpaceIndex = -1;
            columnIndex = 0;
        }
        else
            ++columnIndex;
    }
    
    // Last line
    if (columnIndex > 0)
        [quotedText appendFormat:@"> %@\r\n", [text substringFromIndex:startIndex]];
    return quotedText;
}
@end
