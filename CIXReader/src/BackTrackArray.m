//
//  BackTrackArray.m
//  CIXReader
//
//  Created by Steve on Fri Mar 12 2004.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "BackTrackArray.h"

@implementation BackTrackArray

/* Initialises a new BackTrackArray with the specified maximum number of
 * items.
 */
-(id)initWithMaximum:(NSUInteger)theMax
{
	if ((self = [super init]) != nil)
	{
		_maxItems = theMax;
		_queueIndex = -1;
		_array = [[NSMutableArray alloc] initWithCapacity:_maxItems];
	}
	return self;
}

/* Returns YES if we're at the start of the queue.
 */
-(BOOL)isAtStartOfQueue
{
	return _queueIndex <= 0;
}

/* Returns YES if we're at the end of the queue.
 */
-(BOOL)isAtEndOfQueue
{
	return _queueIndex >= _array.count - 1;
}

/* Removes an item from the tail of the queue as long as the queue is not
 * empty and returns the backtrack data.
 */
-(BOOL)previousItemAtQueue:(Address **)addressPtr
{
	if (_queueIndex > 0)
	{
		*addressPtr = _array[--_queueIndex];
		return YES;
	}
	return NO;
}

/* Removes an item from the tail of the queue as long as the queue is not
 * empty and returns the backtrack data.
 */
-(BOOL)nextItemAtQueue:(Address **)addressPtr
{
	if (_queueIndex < _array.count - 1)
	{
		*addressPtr = _array[++_queueIndex];
		return YES;
	}
	return NO;
}

/* Adds an item to the queue. The new item is added at queueIndex
 * which is the most recent position to which the user has tracked
 * (usually the end of the array if no tracking has occurred). If
 * queueIndex is in the middle of the array, we remove all items
 * to the right (from queueIndex+1 onwards) in order to define a
 * new 'head' position. This produces the expected results when tracking
 * from the new item inserted back to the most recent item.
 */
-(void)addToQueue:(Address *)address
{
	while (_queueIndex + 1 < _array.count)
		[_array removeObjectAtIndex:_queueIndex + 1];
	if (_array.count == _maxItems)
	{
		[_array removeObjectAtIndex:0];
		--_queueIndex;
	}
	if (_array.count > 0)
	{
		Address * itemAddress = _array[_array.count - 1];
		if ([itemAddress.address isEqualToString:address.address])
			return;
	}
	[_array addObject:address];
	++_queueIndex;
}
@end
