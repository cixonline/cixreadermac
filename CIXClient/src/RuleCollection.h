//
//  RuleCollection.h
//  CIXClient
//
//  Created by Steve Palmer on 26/11/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "Rule.h"

@interface RuleCollection : NSObject <NSFastEnumeration> {
    NSMutableArray * _allRules;
}

// Accessors
-(NSArray *)allRules;
-(void)block:(NSString *)username;
-(void)reset;
-(void)save;
-(void)applyRules:(Message *)message;
-(BOOL)applyRule:(Rule *)rule toMessage:(Message *)message;
-(void)addRule:(Rule *)value;
-(void)deleteRule:(Rule *)value;
@end
