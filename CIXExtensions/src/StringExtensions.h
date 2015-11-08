//
//  StringExtensions.h
//  CIXExtensions
//
//  Created by Steve Palmer on 31/07/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#define SafeString(s)       ((s) ? (s) : @"")
#define IsEmpty(s)          ((s) == nil || [s isBlank])
#define BoolToString(s)     NSLocalizedString(((s) ? @"true" : @"false"), nil)

@interface NSMutableString (MutableStringExtensions)
    -(void)replaceString:(NSString *)source withString:(NSString *)dest;
@end

@interface NSString (StringExtensions)
    -(NSString *)quoteAttributes;
    -(NSString *)unquoteAttributes;
    -(NSString *)trim;
    -(NSString *)trimWithCharacter:(char)characterToTrim;
    -(BOOL)isBlank;
    -(BOOL)isNumeric;
    -(NSString *)firstNonBlankLine;
    -(NSString *)truncateByWordWithLimit:(NSInteger)limit;
    -(NSString *)unescapeUnicode;
    -(NSString *)quotedString;
    -(NSString *)stringByChangingPathExtension:(NSString *)ext;
    -(NSUInteger)indexOfCharacterInString:(char)ch afterIndex:(NSUInteger)startIndex;
    -(NSUInteger)indexOfCharactersInString:(NSString *)charString afterIndex:(NSUInteger)startIndex;
    -(NSDate *)fromJSONDate;
    -(NSString *)fromJSONString;
@end

@interface NSAttributedString (AttributedStringExtensions)
    +(NSAttributedString *)stringFromHTMLString:(NSString *)string;
@end
