//
//  Parts.h
//  CIXClient
//
//  Created by Steve Palmer on 09/10/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "JSONModel.h"

@protocol J_Part
@end

@interface J_Part : JSONModel

@property (strong, nonatomic) NSString * Name;

@end

@interface J_Parts : JSONModel

@property (strong, nonatomic) NSArray<J_Part, Optional> * Users;
@property (assign, nonatomic) int Count;
@property (assign, nonatomic) int Start;

@end
