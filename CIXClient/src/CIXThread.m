//
//  CIXThread.m
//  CIXClient
//
//  Created by Steve Palmer on 14/07/2015.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "CIXThread.h"
#import "StringExtensions.h"

@implementation CIXThread

/* Return description of this CIXThread
 */
-(NSString *)description
{
    NSMutableString * text = [NSMutableString stringWithFormat:@"<%@>\n", [self class]];
    [text appendFormat:@"   [author]: %@\n", self.author];
    [text appendFormat:@"   [body]: %@\n", self.body.firstNonBlankLine];
    [text appendFormat:@"   [forum]: %@\n", self.forum];
    [text appendFormat:@"   [topic]: %@\n", self.topic];
    [text appendFormat:@"   [date]: %@\n", self.date];
    [text appendFormat:@"   [remoteID]: %d\n", self.remoteID];
    [text appendFormat:@"</%@>", [self class]];
    return text;
}
@end
