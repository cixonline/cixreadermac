//
//  ForumSet.h
//  CIXClient
//
//  Created by Steve Palmer on 06/10/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "JSONModel.h"

@interface J_Forums : JSONModel

@property (strong, nonatomic) NSString * Name;
@property (strong, nonatomic) NSString * Type;
@property (strong, nonatomic) NSString * Category;
@property (strong, nonatomic) NSString * SubCategory;
@property (strong, nonatomic) NSString * Title;
@property (strong, nonatomic) NSString * Description;

@end
