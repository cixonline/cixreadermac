//
//  Range.h
//  CIXClient
//
//  Created by Steve Palmer on 31/10/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "JSONModel.h"

@protocol J_Range
@end

@interface J_Range : JSONModel

@property (assign, nonatomic) int End;
@property (strong, nonatomic) NSString * ForumName;
@property (assign, nonatomic) int Start;
@property (strong, nonatomic) NSString * TopicName;

@end
