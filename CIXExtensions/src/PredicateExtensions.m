//
//  PredicateExtensions.m
//  CIXExtensions
//
//  Created by Steve Palmer on 17/12/2015.
//  Copyright © 2015 CIXOnline Ltd. All rights reserved.
//

#import "PredicateExtensions.h"

@implementation NSPredicate (PredicateExtensions)

static NSString * SQLNullValueString = @"NULL";

/* Convert this predicate to its SQL equivalent to be used on the right hand side
 * of a WHERE clause.
 */
-(NSString *)SQL
{
    NSString *retVal = nil;
   
    if ([self respondsToSelector:@selector(compoundPredicateType)])
        retVal = [self SQLWhereClauseForCompoundPredicate:(NSCompoundPredicate *)self];
    else if ([self respondsToSelector:@selector(predicateOperatorType)])
        retVal = [self SQLWhereClauseForComparisonPredicate:(NSComparisonPredicate *)self];
    else
        NSAssert(0,@"predicate %@ cannot be converted to SQL because it is not of a convertible class", self);
    return retVal;
}

-(NSString *)SQLExpressionForKeyPath:(NSString *)keyPath
{
    NSString *retStr = keyPath;

    NSDictionary *convertibleSetOperations = @{
            @"@avg" : @"avg",
            @"@max" : @"max",
            @"@min" : @"min",
            @"@sum" : @"sum",
            @"@distinctUnionOfObjects" : @"distinct"
    };

    for (NSString *setOpt in [convertibleSetOperations allKeys])
        if ([keyPath hasSuffix:setOpt])
        {
            NSString * clean = [[keyPath stringByReplacingOccurrencesOfString:setOpt
                                                                 withString:@""]
                                        stringByReplacingOccurrencesOfString:@".."
                                                                 withString:@"."];
            retStr = [NSString stringWithFormat:@"%@(%@)", convertibleSetOperations[setOpt], clean];
        }
    return retStr;
}

-(NSString *)SQLLiteralListForArray:(NSArray *)array
{
    NSMutableArray *retArray = [NSMutableArray array];

    for (NSExpression *obj in array)
        [retArray addObject:[self SQLExpressionForNSExpression:obj]];

    return [NSString stringWithFormat:@"(%@)",[retArray componentsJoinedByString:@","]];
}

-(NSString *)SQLConstantForValue:(id)val
{
    NSString *retStr = nil;

    if ([val isKindOfClass:[NSString class]])
        retStr = [NSString stringWithFormat:@"'%@'", [val stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"]];
    else if ([val respondsToSelector:@selector(intValue)])
        retStr = [val stringValue];
    else if ([val isEqual:[NSNull null]] || val == nil )
        retStr = SQLNullValueString;
    else
        retStr = [self SQLConstantForValue:[val description]];
    return retStr;
}

-(NSString *)SQLInfixOperatorForOperatorType:(NSPredicateOperatorType)type
{
    NSString *comparator = nil;
    switch (type) {
        case NSLessThanPredicateOperatorType:               comparator = @"<";      break;
        case NSLessThanOrEqualToPredicateOperatorType:      comparator = @"<=";     break;
        case NSGreaterThanPredicateOperatorType:            comparator = @">";      break;
        case NSGreaterThanOrEqualToPredicateOperatorType:   comparator = @">=";     break;
        case NSEqualToPredicateOperatorType:                comparator = @"IS";     break;
        case NSNotEqualToPredicateOperatorType:             comparator = @"IS NOT"; break;
        case NSMatchesPredicateOperatorType:                comparator = @"MATCH";  break;
        case NSInPredicateOperatorType:                     comparator = @"IN";     break;
        case NSBetweenPredicateOperatorType:                comparator = @"BETWEEN";break;

        case NSLikePredicateOperatorType:
            NSAssert(false, @"predicate cannot be converted to a where clause because 'like' "
                     "uses an pattern matching syntax which is not converted at this "
                     "time.  Use 'MATCHES' instead.");
            break;

        case NSContainsPredicateOperatorType:
        case NSBeginsWithPredicateOperatorType:
        case NSEndsWithPredicateOperatorType:
            NSAssert(0,@"predicate cannot be converted to a where clause because 'beginswith' "
                        "and 'endswith' are not consistently supported by SQL");
            break;
       
        case NSCustomSelectorPredicateOperatorType:
            NSAssert(0,@"predicate cannot be converted to a where clause because it calls a"
                        "custom selector");
            break;
    }
    return comparator;
}

-(NSString *)SQLWhereClauseForComparisonPredicate:(NSComparisonPredicate *)predicate
{
    NSString *retStr = nil;
    NSString *comparator = nil;
   
    if (!retStr)
        comparator = [self SQLInfixOperatorForOperatorType:[predicate predicateOperatorType]];

    NSAssert(comparator, @"Predicate %@ could not be converted, the predicate operator could not be converted.", predicate);
   
    if (!retStr) {
        if ([comparator isEqual:@"BETWEEN"]) {
            retStr = [NSString stringWithFormat:@"(%@ %@ %@ AND %@)",
                      [self SQLExpressionForNSExpression:[predicate leftExpression]],
                        comparator,
                        [self SQLExpressionForNSExpression:[[predicate rightExpression] collection][0]],
                        [self SQLExpressionForNSExpression:[[predicate rightExpression] collection][1]]];
        } else {
            retStr = [NSString stringWithFormat:@"(%@ %@ %@)",
                      [self SQLExpressionForNSExpression:[predicate leftExpression]],
                      comparator,
                      [self SQLExpressionForNSExpression:[predicate rightExpression]]];
        }
    }

    return retStr;
}

-(NSString *)SQLNamedReplacementVariableForVariable:(NSString *)var
{
    NSAssert(0,@"%s Not Implemented",__func__);
    return nil;
}

-(NSString *)SQLSelectClauseForSubqueryExpression:(NSExpression *)expression
{
    NSString *retStr = nil;
    NSAssert(0,@"%s Not Implemented",__func__);
    return retStr;
}

-(NSString *)SQLFunctionLiteralForFunctionExpression:(NSExpression *)expression
{
    NSString *retStr = nil;
    NSDictionary *convertibleNullaryFunctions = @{@"now"    : @"date('now')",
                                                  @"random" : @"random()"
                                                  };
    
    NSDictionary *convertibleUnaryFunctions = @{@"uppercase:" : @"upper",
                                                @"lowercase:" : @"lower",
                                                @"abs:"       : @"abs"
                                                };
    
    NSDictionary *convertibleBinaryFunctions = @{@"add:to:"        : @"+" ,
                                                 @"from:subtract:" : @"-" ,
                                                 @"multiply:by:"   : @"*" ,
                                                 @"divide:by:"     : @"/" ,
                                                 @"modulus:by:"    : @"%" ,
                                                 @"leftshift:by"   : @"<<",
                                                 @"rightshift:by:" : @">>"
                                                 };
    
    if ([convertibleNullaryFunctions objectForKey:expression.function])
        retStr = convertibleNullaryFunctions[expression.function];
    else if ([convertibleUnaryFunctions objectForKey:expression.function])
        retStr = [NSString stringWithFormat:@"%@(%@)",
                  convertibleUnaryFunctions[expression.function],
                  [self SQLExpressionForNSExpression:expression.arguments[0]]
                 ];
    else if ([convertibleBinaryFunctions objectForKey:expression.function])
        retStr = [NSString stringWithFormat:@"(%@ %@ %@)",
                  [self SQLExpressionForNSExpression:expression.arguments[0]],
                  convertibleBinaryFunctions[expression.function],
                   [self SQLExpressionForNSExpression:expression.arguments[1]]
                  ];
    else
        NSAssert(0,@"the expression %@ could not be converted because it uses an unconvertible function %@", expression, expression.function);
    return retStr;
}


-(NSString *)SQLExpressionForNSExpression:(NSExpression *)expression
{
    NSString *retStr = nil;

    switch ([expression expressionType]) {
        case NSConstantValueExpressionType:
            retStr = [self SQLConstantForValue:[expression constantValue]];
            break;

        case NSVariableExpressionType:
            retStr = [self SQLNamedReplacementVariableForVariable:[expression variable]];
            break;

        case NSKeyPathExpressionType:
            retStr = [self SQLExpressionForKeyPath:[expression keyPath]];
            break;

        case NSFunctionExpressionType:
            retStr = [self SQLFunctionLiteralForFunctionExpression:expression];
            break;

        case NSSubqueryExpressionType:
            retStr = [self SQLSelectClauseForSubqueryExpression:expression];
            break;

        case NSAggregateExpressionType:
            retStr = [self SQLLiteralListForArray:[expression collection]];
            break;
      
        case NSUnionSetExpressionType:
        case NSIntersectSetExpressionType:
        case NSMinusSetExpressionType:
            // impl
            break;
        /* these can't be converted */
        case NSEvaluatedObjectExpressionType:
        case NSBlockExpressionType:
        case NSAnyKeyExpressionType:
        case NSConditionalExpressionType:
            break;
    }
    return retStr;
}

-(NSString *)SQLWhereClauseForCompoundPredicate:(NSCompoundPredicate *)predicate
{
    NSMutableArray *subs = [NSMutableArray array];
   
    for (NSPredicate *sub in [predicate subpredicates])
        [subs addObject:sub.SQL];

    NSString *conjunction;
    switch ([(NSCompoundPredicate *)predicate compoundPredicateType])
    {
        case NSAndPredicateType:
            conjunction = @" AND ";
            break;
        case NSOrPredicateType:
            conjunction = @" OR ";
            break;
        case NSNotPredicateType:
            conjunction = @" NOT ";
            break;
    }
    return [NSString stringWithFormat:@"( %@ )", [subs componentsJoinedByString:conjunction]];
}
@end
