//
//  CategoryResultSet.h
//  CIXClient
//
//  Created by Steve Palmer on 25/09/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "JSONModel.h"

@protocol J_Category
@end

@interface J_Category : JSONModel

@property (strong, nonatomic) NSString * Name;
@property (strong, nonatomic) NSString * Sub;

@end

@interface J_CategoryResultSet : JSONModel

@property (strong, nonatomic) NSArray<J_Category, Optional> * Categories;
@property (assign, nonatomic) int Count;
@property (assign, nonatomic) int Start;

@end
