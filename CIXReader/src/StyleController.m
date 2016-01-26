//
//  StyleController.m
//  CIXReader
//
//  Created by Steve Palmer on 24/10/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "CIX.h"
#import "AppDelegate.h"
#import "StyleController.h"
#import "StringExtensions.h"
#import "DateExtensions.h"
#import "FileManagerExtensions.h"
#import "CIXMarkup.h"
#import "Preferences.h"

// Styles path mappings is global across all instances
static NSMutableDictionary * _stylePathMappings = nil;
static NSDictionary * _mapEmoticonToName = nil;

@implementation StyleController

/* initForStyle
 * Initialise the template and stylesheet for the specified display style if it can be
 * found. Otherwise the existing template and stylesheet are not changed.
 */
-(id)initForStyle:(NSString *)styleName
{
    if ((self = [super init]) != nil)
    {
        _styleName = styleName;
        _inited = NO;
    }
    return self;
}

/* Load the styles map from the styles folder.
 */
+(void)loadStylesMap
{
    if (_stylePathMappings == nil)
        _stylePathMappings = [[NSMutableDictionary alloc] init];
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    
    NSString * path = [[[NSBundle mainBundle] sharedSupportPath] stringByAppendingPathComponent:@"Styles"];
    [fileManager loadMapFromPath:path mappings:_stylePathMappings foldersOnly:YES extensions:nil];
    
    path = [CIX.homeFolder stringByAppendingPathComponent:@"Styles"];
    [fileManager loadMapFromPath:path mappings:_stylePathMappings foldersOnly:YES extensions:nil];
}

/** Return an NSArray of all styles
 
 @return An NSArray of all styles
 */
-(NSArray *)allStyles
{
    if (_stylePathMappings == nil)
        [StyleController loadStylesMap];
    
    return _stylePathMappings.allKeys;
}

/* Initialise the template and stylesheet for the specified display style if it can be
 * found. Otherwise the existing template and stylesheet are not changed.
 */
-(void)loadStyle
{
    if (_stylePathMappings == nil)
        [StyleController loadStylesMap];
    
    if (!_inited)
    {
        NSString * path = [_stylePathMappings objectForKey:_styleName];
        if (path != nil)
        {
            NSString * filePath = [path stringByAppendingPathComponent:@"template.html"];
            NSString * templateString = [NSString stringWithContentsOfFile:filePath usedEncoding:NULL error:NULL];
            
            // Sanity check the file. Obviously anything bigger than 0 bytes but smaller than a valid template
            // format is a problem but we'll worry about that later. There's only so much rope we can give.
            if (templateString != nil && [templateString length] > 0u)
            {
                _htmlTemplate = templateString;
                _cssStylesheet = [@"file://localhost" stringByAppendingString:[path stringByAppendingPathComponent:@"stylesheet.css"]];
                
                NSString * javaScriptPath = [path stringByAppendingPathComponent:@"script.js"];
                if ([[NSFileManager defaultManager] fileExistsAtPath:javaScriptPath])
                    _jsScript = [@"file://localhost" stringByAppendingString:javaScriptPath];
                else
                    _jsScript = nil;
                
                // Make sure the template is valid
                NSString * firstLine = [[_htmlTemplate firstNonBlankLine] lowercaseString];
                if ([firstLine hasPrefix:@"<html>"] || [firstLine hasPrefix:@"<!doctype"])
                {
                    _htmlTemplate = nil;
                    _jsScript = nil;
                    _cssStylesheet = nil;
                }
            }
        }
        _inited = YES;
    }
}

/** Decode a tag that resolves into a mugshot URL.
 
 @param tag The tag argument
 @return An NSString that specifies the mugshot URL using the tag
 */
-(NSString *)imageFromTag:(NSString *)tag
{
    return [NSString stringWithFormat:@"mugshot:%@", tag];
}

-(NSString *)stringFromTag:(NSString *)tag
{
    return SafeString(tag);
}

-(NSString *)dateFromTag:(NSDate *)tag
{
    return [[tag GMTBSTtoUTC] friendlyDescription];
}

-(NSString *)htmlFromTag:(NSString *)tag
{
    Preferences * prefs = [Preferences standardPreferences];
    NSMutableString * modifiedString = [NSMutableString stringWithString:(prefs.ignoreMarkup) ? [tag quoteAttributes] : tag];
    
    NSError * error = NULL;
    
    if (!IsEmpty(self.highlightString))
    {
        NSString * linkPattern = [NSString stringWithFormat:@"(%@)", self.highlightString];
        NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:linkPattern options:NSRegularExpressionCaseInsensitive error:&error];
        [regex replaceMatchesInString:modifiedString options:0 range:NSMakeRange(0, [modifiedString length]) withTemplate:@"<font style=\"BACKGROUND-COLOR: yellow\">$1</font>"];
    }
    
    // Render markup if permitted
    if (prefs.ignoreMarkup)
        [modifiedString replaceString:@"\n" withString:@"<br />"];
    else
    {
        NSString * markedString = [CIXMarkup markupToHTML:modifiedString];
        modifiedString = [markedString mutableCopy];
    }
    
    // Convert HTTP:// (etc) and www / ftp (etc) links to actual links.
    NSString * linkPattern = @"(((http|https|ftp|news|file)+://|www\\.|ftp\\.)[&#95;.a-z0-9-]+[a-z0-9/&#95;:@=.+?,#!$_%&()~-]*[^.|\'|# |!|\(|?|,| |>|<|;|)])";
    NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:linkPattern options:NSRegularExpressionCaseInsensitive error:&error];
    [regex replaceMatchesInString:modifiedString options:0 range:NSMakeRange(0, [modifiedString length]) withTemplate:@"<a href=\"$1\">$1</a>"];
    [modifiedString replaceString:@"href=\"www" withString:@"href=\"http://www"];
    
    // Catch mailto links
    linkPattern = @"(mailto:\\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}\\b)";
    regex = [NSRegularExpression regularExpressionWithPattern:linkPattern options:NSRegularExpressionCaseInsensitive error:&error];
    [regex replaceMatchesInString:modifiedString options:0 range:NSMakeRange(0, [modifiedString length]) withTemplate:@"<a href=\"$1\">$1</a>"];
    
    // Make cix: style links clickable
    linkPattern = @"(cix\\:[a-z0-9._\\-:/]*[a-z0-9]+)";
    regex = [NSRegularExpression regularExpressionWithPattern:linkPattern options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSRange textRange = NSMakeRange(0, modifiedString.length);
    NSTextCheckingResult * result = [regex firstMatchInString:modifiedString options:0 range:textRange];
    while (result != nil && result.range.location != NSNotFound)
    {
        NSString * match = [modifiedString substringWithRange:result.range];
        Message * message = [(AppDelegate *)[NSApp delegate] messageFromAddress:match];
        NSString * popupText = @"";

        if (message != nil)
            popupText = [NSString stringWithFormat:@"<span class=\"tooltip_text\">%@</span>", [[message body] truncateByWordWithLimit:200]];
        
        NSString * fmt = [NSString stringWithFormat:@"<a onmouseover=\"tooltipShow(event,this)\" onmouseout=\"tooltipHide(event,this)\" href=\"%@\">%@%@</a>", match, match, popupText];

        [modifiedString deleteCharactersInRange:result.range];
        [modifiedString insertString:fmt atIndex:result.range.location];

        textRange.location = result.range.location + fmt.length;
        textRange.length = modifiedString.length - textRange.location;
        
        result = [regex firstMatchInString:modifiedString options:0 range:textRange];
    }
    
    // Make cixfile: links into URL links.
    linkPattern = @"cixfile\\:([a-z0-9._\\-]+)/([a-z0-9._\\-]+):([a-z0-9\\/&#95;:@=.+?,#_%&~-]+)";
    regex = [NSRegularExpression regularExpressionWithPattern:linkPattern options:NSRegularExpressionCaseInsensitive error:&error];
    [regex replaceMatchesInString:modifiedString options:0 range:NSMakeRange(0, [modifiedString length]) withTemplate:@"<a href=\"http://forums.cix.co.uk/secure/cixfile.aspx?forum=$1&topic=$2&file=$3\">cixfile:$1/$2:$3</a>"];
    
    // Make attach: elements into img tags
    linkPattern = @"(attach:[0-9]+/[0-9]+/[0-9]+)";
    regex = [NSRegularExpression regularExpressionWithPattern:linkPattern options:NSRegularExpressionCaseInsensitive error:&error];
    [regex replaceMatchesInString:modifiedString options:0 range:NSMakeRange(0, [modifiedString length]) withTemplate:@"<img src=\"$1\" />"];
    
    // Make http links to image files into img links so we can have inline images
    if (prefs.downloadInlineImages)
    {
        NSString * linkPattern = @"(<a href=\"(http|https):.*?.(?:jpe?g|gif|png).*?\">)(.*?)(</a>)";
        NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:linkPattern options:NSRegularExpressionCaseInsensitive error:&error];
        [regex replaceMatchesInString:modifiedString options:0 range:NSMakeRange(0, [modifiedString length]) withTemplate:@"$1<img width=30% border=\"0\" src=\"$3\" />$4"];
        
        // Look for src="https://www.dropbox.com" and append the raw marker to it.
        linkPattern = @"(src=\")(https:\\/\\/www\\.dropbox\\.com.*?)(\\?dl=0)*(\")";
        regex = [NSRegularExpression regularExpressionWithPattern:linkPattern options:NSRegularExpressionCaseInsensitive error:&error];
        [regex replaceMatchesInString:modifiedString options:0 range:NSMakeRange(0, [modifiedString length]) withTemplate:@"$1$2?raw=1$4"];
    }
    
    // Replace emoticons with their graphical equivalent.
    if (!prefs.ignoreMarkup)
        [self replaceEmoticons:modifiedString];
    
    return [NSString stringWithFormat:@"<p>%@</p>", modifiedString];
}

/* Convert any emoticons in the string to references to their
 * actual file in the bundle.
 */
-(void)replaceEmoticons:(NSMutableString *)source
{
    if (_mapEmoticonToName == nil)
        _mapEmoticonToName = @{@":-)" : @"smiley",
                               @":-D" : @"laugh",
                               @":-(" : @"frown",
                               @";-)" : @"wink",
                               @"8-)" : @"shades"};
    
    for (NSString * key in _mapEmoticonToName.allKeys)
    {
        NSString * emoticon = _mapEmoticonToName[key];
        
        NSString * filePath = [[NSBundle mainBundle] pathForResource:emoticon ofType:@"tiff"];
        NSURL * fileURL = [NSURL fileURLWithPath:filePath];
        
        [source replaceString:key withString:[NSString stringWithFormat:@"<img src=\"%@\" />", fileURL.absoluteString]];
    }
}

/** Return an NSString containing the tagged item collection formatted as HTML
 
 This method iterates over the items in the collection and creates an NSString that contains
 the items using the specified style template if one was specified.
 */
-(NSString *)styledTextForCollection:(NSArray *)array
{
    NSUInteger index;
    
    [self loadStyle];

    NSString * libpath = [[[NSBundle mainBundle] sharedSupportPath] stringByAppendingPathComponent:@"Styles/Library"];
    libpath = [@"file://localhost" stringByAppendingString:libpath];
    
    NSMutableString * htmlText = [[NSMutableString alloc] initWithString:@"<!DOCTYPE html><html><head><meta charset=\"UTF-8\" />"];
    if (_cssStylesheet != nil)
    {
        [htmlText appendString:@"<link rel=\"stylesheet\" type=\"text/css\" href=\""];
        [htmlText appendString:_cssStylesheet];
        [htmlText appendString:@"\"/>"];
    }
    [htmlText appendFormat:@"<link rel=\"stylesheet\" type=\"text/css\" href=\"%@/popup.css\"/>", libpath];
    if (_jsScript != nil)
    {
        [htmlText appendString:@"<script type=\"text/javascript\" src=\""];
        [htmlText appendString:_jsScript];
        [htmlText appendString:@"\"/></script>"];
    }
    [htmlText appendFormat:@"<script type=\"text/javascript\" src=\"%@/popup.js\"/></script>", libpath];
    [htmlText appendString:@"<meta http-equiv=\"Pragma\" content=\"no-cache\">"];
    [htmlText appendString:@"</head><body>"];
    for (index = 0; index < array.count; ++index)
    {
        id item = array[index];
        
        // Load the selected HTML template for the current view style and plug in the current
        // article values and style sheet setting.
        NSMutableString * htmlMessage;
        if (_htmlTemplate == nil)
        {
            SEL selector = NSSelectorFromString(@"unformattedText");
            IMP imp = [item methodForSelector:selector];
            NSString * (*func)(id, SEL) = (void *)imp;
            
            NSMutableString * articleBody = [NSMutableString stringWithString:func(item, selector)];
            htmlMessage = [[NSMutableString alloc] initWithString:articleBody];
        }
        else
        {
            htmlMessage = [[NSMutableString alloc] initWithString:@""];
            NSScanner * scanner = [NSScanner scannerWithString:_htmlTemplate];
            NSString * theString = nil;
            BOOL stripIfEmpty = NO;
            
            // Handle conditional tag expansion. Sections in <!-- cond:noblank--> and <!--end-->
            // are stripped out if all the tags inside are blank.
            while(![scanner isAtEnd])
            {
                if ([scanner scanUpToString:@"<!--" intoString:&theString])
                    [htmlMessage appendString:[self expandTags:theString withItem:item withConditional:stripIfEmpty]];
                
                if ([scanner scanString:@"<!--" intoString:nil])
                {
                    NSString * commentTag = nil;
                    
                    if ([scanner scanUpToString:@"-->" intoString:&commentTag] && commentTag != nil)
                    {
                        commentTag = [commentTag trim];
                        if ([commentTag isEqualToString:@"cond:noblank"])
                            stripIfEmpty = YES;
                        if ([commentTag isEqualToString:@"end"])
                            stripIfEmpty = NO;
                        [scanner scanString:@"-->" intoString:nil];
                    }
                }
            }
        }
        
        // Separate each message with a horizontal divider line
        if (index > 0)
            [htmlText appendString:@"<hr><br />"];
        [htmlText appendString:htmlMessage];
    }
    [htmlText appendString:@"</body></html>"];
    return htmlText;
}

/* Expands recognised tags in theString based on the object values.
 */
-(NSString *)expandTags:(NSString *)theString withItem:(id)item withConditional:(BOOL)cond
{
    NSMutableString * newString = [NSMutableString stringWithString:theString];
    BOOL hasOneTag = NO;
    NSUInteger tagStartIndex = 0;
    
    while ((tagStartIndex = [newString indexOfCharacterInString:'$' afterIndex:tagStartIndex]) != NSNotFound)
    {
        NSUInteger tagEndIndex = [newString indexOfCharacterInString:'$' afterIndex:tagStartIndex + 1];
        if (tagEndIndex == NSNotFound)
            break;
        
        NSUInteger tagLength = (tagEndIndex - tagStartIndex) + 1;
        NSString * tagName = [newString substringWithRange:NSMakeRange(tagStartIndex + 1, tagLength - 2)];
        NSString * replacementString = nil;
        
        // Use the tag name as the selector to a member function that returns the expanded
        // value. If no function exists then we just delete the tag name from the source string.
        NSString * tagSelName = [NSString stringWithFormat:@"tag%@:", tagName];
        
        SEL selector = NSSelectorFromString(tagSelName);
        IMP imp = [item methodForSelector:selector];
        NSString * (*func)(id, SEL, StyleController *) = (void *)imp;
        replacementString = func(item, selector, self);
        
        if (replacementString == nil)
            [newString deleteCharactersInRange:NSMakeRange(tagStartIndex, tagLength)];
        else
        {
            [newString replaceCharactersInRange:NSMakeRange(tagStartIndex, tagLength) withString:replacementString];
            hasOneTag = YES;
            
            if (![replacementString isBlank])
                cond = NO;
            
            tagStartIndex += [replacementString length];
        }
    }
    return (cond && hasOneTag) ? @"" : newString;
}
@end
