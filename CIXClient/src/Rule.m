//
//  Rule.m
//  CIXClient
//
//  Created by Steve Palmer on 26/11/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "Rule.h"
#import "StringExtensions.h"

@implementation Rule

-(id)initWithTitle:(NSString *)title predicate:(NSPredicate *)predicate actionCode:(NSUInteger)actionCode active:(BOOL)active
{
    if ((self = [super init]) != nil)
    {
        self.active = active;
        self.title = title;
        self.predicate = predicate;
        self.actionCode = actionCode;
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeBool:self.active forKey:@"Active"];
    [encoder encodeObject:self.title forKey:@"Title"];
    [encoder encodeObject:self.predicate forKey:@"Predicate"];
    [encoder encodeInteger:self.actionCode forKey:@"ActionCode"];
}

-(id)initWithCoder:(NSCoder *)decoder
{
    BOOL active = [decoder decodeBoolForKey:@"Active"];
    NSString * title = [decoder decodeObjectForKey:@"Title"];
    NSUInteger actionCode = [decoder decodeIntegerForKey:@"ActionCode"];
    NSPredicate * predicate = [decoder decodeObjectForKey:@"Predicate"];
    return [self initWithTitle:title predicate:predicate actionCode:actionCode active:active];
}

/** Returns a description of this object.
 */
-(NSString *)description
{
    NSMutableString * text = [NSMutableString stringWithFormat:@"<%@>\n", [self class]];
    [text appendFormat:@"   [active]: %@\n", BoolToString(self.active)];
    [text appendFormat:@"   [title]: %@\n", self.title];
    [text appendFormat:@"   [predicate]: %@\n", self.predicate];
    [text appendFormat:@"   [actionCode]: %ld\n", (long)self.actionCode];
    [text appendFormat:@"</%@>", [self class]];
    return text;
}
@end
