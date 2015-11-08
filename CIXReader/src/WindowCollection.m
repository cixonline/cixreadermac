//
//  WindowCollection.m
//  CIXReader
//
//  Created by Steve Palmer on 12/09/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "WindowCollection.h"

@implementation WindowCollection

/* Return the default collection.
 */
+(WindowCollection *)defaultCollection
{
    static WindowCollection * sharedCollection = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCollection = [[self alloc] init];
    });
    return sharedCollection;
}

/* Initialise the empty collection.
 */
-(id)init
{
    if ((self = [super init]) != nil)
        _collection = [[NSMutableArray alloc] init];
    return self;
}

/* Add the specified controller to the collection. No
 * check is made to ensure it is not already present.
 */
-(void)add:(NSWindowController *)value
{
    [_collection addObject:value];
}

/* Remove the specified controller from the collection. No
 * check is made to ensure it is present.
 */
-(void)remove:(NSWindowController *)value
{
    [_collection removeObject:value];
}

/* Return the window collection
 */
-(NSArray *)collection
{
    return _collection;
}
@end
