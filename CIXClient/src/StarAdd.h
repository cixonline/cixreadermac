//
//  StarAdd.h
//  CIXClient
//
//  Created by Steve Palmer on 12/11/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "JSONModel.h"

@interface J_StarAdd : JSONModel

@property (strong, nonatomic) NSString * Forum;
@property (strong, nonatomic) NSString * Topic;
@property (assign, nonatomic) int MsgID;

@end
