//
//  StarSet.h
//  CIXClient
//
//  Created by Steve Palmer on 10/11/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "JSONModel.h"

@protocol J_Star
@end

@interface J_Star : JSONModel

@property (strong, nonatomic) NSString * Author;
@property (strong, nonatomic) NSString * Conf;
@property (assign, nonatomic) int MsgID;
@property (strong, nonatomic) NSString * PostedDate;
@property (strong, nonatomic) NSString * Subject;
@property (strong, nonatomic) NSString * Topic;
@property (strong, nonatomic) NSString * starID;

@end

@interface J_StarSet : JSONModel

@property (strong, nonatomic) NSArray<J_Star, Optional> * Stars;
@property (assign, nonatomic) int Count;
@property (assign, nonatomic) int Start;

@end
