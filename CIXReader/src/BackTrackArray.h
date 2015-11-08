//
//  BackTrackArray.h
//  CIXReader
//
//  Created by Steve on Fri Mar 12 2004.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "CIX.h"
#import "Address.h"

@interface BackTrackArray : NSObject {
@private
	NSMutableArray * _array;
	NSUInteger _maxItems;
	int _queueIndex;
}

// Accessor functions
-(id)initWithMaximum:(NSUInteger )theMax;
-(BOOL)isAtStartOfQueue;
-(BOOL)isAtEndOfQueue;
-(void)addToQueue:(Address *)address;
-(BOOL)nextItemAtQueue:(Address **)addressPtr;
-(BOOL)previousItemAtQueue:(Address **)addressPtr;
@end
