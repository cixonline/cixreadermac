//
//  RuleCollection.m
//  CIXClient
//
//  Created by Steve Palmer on 26/11/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "RuleCollection.h"
#import "CIX.h"

@implementation RuleCollection

/* Initialise ourself.
 */
-(id)init
{
    if ((self = [super init]) != nil)
        [self createDefaultRules];

    return self;
}

/* Create the default list of rules.
 */
-(void)createDefaultRules
{
    NSBundle * thisBundle = [NSBundle bundleForClass:[self class]];
    [self parseRuleFromFile:[thisBundle pathForResource:@"MessageRules" ofType:@"plist"]];
    
    // Merge in custom rules
    NSString * userRules = [[CIX homeFolder] stringByAppendingPathComponent:@"MessageRules.plist"];
    [self parseRuleFromFile:userRules];
}

/* Save the rules to a user file.
 */
-(void)save
{
    NSString * userRules = [[CIX homeFolder] stringByAppendingPathComponent:@"MessageRules.plist"];
    
    NSMutableData * data = [[NSMutableData alloc] init];
    NSKeyedArchiver * archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver setOutputFormat:NSPropertyListXMLFormat_v1_0];
    [archiver encodeObject:_allRules forKey:@"root"];
    [archiver finishEncoding];
    
    [data writeToFile:userRules atomically:YES];
}

/* Read the rules from the specified file.
 */
-(void)parseRuleFromFile:(NSString *)filename
{
    BOOL isDirectory;
    if ([[NSFileManager defaultManager] fileExistsAtPath:filename isDirectory:&isDirectory] && !isDirectory)
    {
        NSData * codedData = [[NSData alloc] initWithContentsOfFile:filename];
        if (codedData != nil)
        {
            NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:codedData];
            _allRules = [unarchiver decodeObjectForKey:@"root"];
            [unarchiver finishDecoding];
        }
    }
}

/* Return the rule whose title matches the one specified.
 */
-(Rule *)ruleByTitle:(NSString *)title
{
    for (Rule * rule in _allRules)
        if ([rule.title isEqualToString:title])
            return rule;
    return nil;
}

/** Return an NSArray of all the global rule predicates
 
 Each element in the array is a Rule object.
 
 @return An NSArray of rules.
 */
-(NSArray *)allRules
{
    return _allRules;
}

/** Add the new rule to the collection
 
 @param value A new Rule object to be added.
 */
-(void)addRule:(Rule *)value
{
    if (_allRules == nil)
        _allRules = [NSMutableArray array];
    [_allRules addObject:value];
}

/** Delete the rule from the collection
 
 @param value The Rule object to be deleted.
 */
-(void)deleteRule:(Rule *)value
{
    [_allRules removeObject:value];
}

/** Reset rules to the default

 Handy for when the user deletes the default set and needs to get back
 to the baseline set of rules.
 */
-(void)reset
{
    _allRules = nil;

    // Blow away any user custom rules
    NSString * userRules = [[CIX homeFolder] stringByAppendingPathComponent:@"MessageRules.plist"];
    NSError * error;
    
    [[NSFileManager defaultManager] removeItemAtPath:userRules error:&error];

    [self createDefaultRules];
}

/** Apply rules to the specified message
 
 On completion of this method, the fields in the specified message will have
 been updated based on the rule handlers.
 
 @param message The message to which the rules should be applied
 */
-(void)applyRules:(Message *)message
{
    for (Rule * rule in _allRules)
        if (rule.active && [rule.predicate evaluateWithObject:message])
        {
            BOOL isClear = (rule.actionCode & CC_Rule_Clear) == CC_Rule_Clear;
            if ((rule.actionCode & CC_Rule_Unread) == CC_Rule_Unread)
            {
                if (!message.readLocked)
                {
                    BOOL oldState = message.unread;
                    message.unread = !isClear;
                    if (oldState != message.unread)
                    {
                        message.readPending = YES;
                        
                        Folder * folder = [CIX.folderCollection folderByID:message.topicID];
                        folder.markReadRangePending = YES;
                    }
                }
            }
            
            if ((rule.actionCode & CC_Rule_Priority) == CC_Rule_Priority)
                message.priority = !isClear;
            
            if ((rule.actionCode & CC_Rule_Ignored) == CC_Rule_Ignored)
            {
                message.ignored = !isClear;
                if (message.ignored && message.unread)
                {
                    message.unread = NO;
                    message.readPending = YES;

                    Folder * folder = [CIX.folderCollection folderByID:message.topicID];
                    folder.markReadRangePending = YES;
                }
            }
            
            if ((rule.actionCode & CC_Rule_Flag) == CC_Rule_Flag)
            {
                BOOL oldState = message.starred;
                message.starred = !isClear;
                if (oldState != message.starred)
                    message.starPending = YES;
            }
        }
}

/* Support fast enumeration on the folders list.
 */
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])stackbuf count:(NSUInteger)len
{
    return [_allRules countByEnumeratingWithState:state objects:stackbuf count:len];
}
@end
