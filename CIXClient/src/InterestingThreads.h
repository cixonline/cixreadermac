//
//  InterestingThreads.h
//  CIXClient
//
//  Created by Steve Palmer on 14/07/2015.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "JSONModel.h"

@protocol J_InterestingThread
@end

@interface J_InterestingThread : JSONModel

@property (strong, nonatomic) NSString * Author;
@property (strong, nonatomic) NSString * Body;
@property (strong, nonatomic) NSString * DateTime;
@property (strong, nonatomic) NSString * Forum;
@property (assign, nonatomic) int RootID;
@property (strong, nonatomic) NSString * Topic;

@end

@interface J_InterestingThreadSet : JSONModel

@property (strong, nonatomic) NSArray<J_InterestingThread, Optional> * Messages;
@property (assign, nonatomic) int Count;
@property (assign, nonatomic) int Start;

@end
