//
//  WindowCollection.h
//  CIXReader
//
//  Created by Steve Palmer on 12/09/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

@interface WindowCollection : NSObject {
    NSMutableArray * _collection;
}

// Accessors
+(WindowCollection *)defaultCollection;
-(void)add:(NSWindowController *)value;
-(void)remove:(NSWindowController *)value;
-(NSArray *)collection;
@end
