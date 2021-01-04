//
//  Address.m
//  CIXReader
//
//  Created by Steve Palmer on 08/10/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "Address.h"
#import "StringExtensions.h"

@implementation Address

/* Initialise an Address object with the given address. Once
 * initialised, the portions of the address are immediately
 * accessible via the properties.
 */
-(id)initWithString:(NSString *)address
{
    if ((self = [super init]) != nil)
        [self parseAddress:address];
    return self;
}

/* Parse an address into its scheme, query and data portions.
 */
-(void)parseAddress:(NSString *)address
{
    if (address != nil)
    {
        NSInteger index = [address indexOfCharacterInString:':' afterIndex:0];
        if (index == NSNotFound)
        {
            self.data = address;
            self.schemeAndQuery = address;
        }
        else
        {
            self.scheme = [address substringToIndex:index];
            
            // Locate optional data that follows query
            NSString * queryPart = [address substringFromIndex:index + 1];
            
            index = [queryPart indexOfCharacterInString:':' afterIndex:0];
            if (index == NSNotFound)
            {
                if ([queryPart isNumeric])
                    self.data = queryPart;
                else
                    self.query = queryPart;
            }
            else
            {
                self.data = [queryPart substringFromIndex:index + 1];
                self.query = [queryPart substringToIndex:index];
            }
        }
    }
    _address = address;
}

/* Set the query property and derive the combined scheme and
 * query from the new value.
 */
-(void)setQuery:(NSString *)query
{
    _query = query;
    _schemeAndQuery = [NSString stringWithFormat:@"%@:%@", self.scheme, self.query];
}

/* Return the original address.
 */
-(NSString *)address
{
    return _address;
}

/** Returns a description of this object.
 */
-(NSString *)description
{
    NSMutableString * text = [NSMutableString stringWithFormat:@"<%@>\n", [self class]];
    [text appendFormat:@"   [scheme]: %@\n", self.scheme];
    [text appendFormat:@"   [query]: %@\n", self.query];
    [text appendFormat:@"   [data]: %@\n", self.data];
    [text appendFormat:@"</%@>", [self class]];
    return text;
}
@end
