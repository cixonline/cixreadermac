//
//  ForumDetailsGet.h
//  CIXClient
//
//  Created by Steve Palmer on 02/10/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "JSONModel.h"

@interface J_ForumDetailsGet : JSONModel

@property (strong, nonatomic) NSString * Category;
@property (strong, nonatomic) NSString * Description;
@property (strong, nonatomic) NSString * FirstPost;
@property (strong, nonatomic) NSString * LastPost;
@property (strong, nonatomic) NSString * Name;
@property (assign, nonatomic) int Recent;
@property (strong, nonatomic) NSString * SubCategory;
@property (strong, nonatomic) NSString * Title;
@property (assign, nonatomic) int Topics;
@property (strong, nonatomic) NSString * Type;

@end

