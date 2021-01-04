//
//  Who.h
//  CIXClient
//
//  Created by Steve Palmer on 14/07/2015.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "JSONModel.h"

@protocol J_Who
@end

@interface J_Who : JSONModel

@property (strong, nonatomic) NSString * Name;
@property (assign, nonatomic) NSString * LastOn;

@end

@interface J_Whos : JSONModel

@property (strong, nonatomic) NSArray<J_Who, Optional> * Users;
@property (assign, nonatomic) int Count;
@property (assign, nonatomic) int Start;

@end
