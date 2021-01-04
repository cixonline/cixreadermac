//
//  ForumMods.h
//  CIXClient
//
//  Created by Steve Palmer on 03/10/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "JSONModel.h"

@protocol J_Mod
@end

@interface J_Mod : JSONModel

@property (strong, nonatomic) NSString * Name;

@end

@interface J_ForumMods : JSONModel

@property (strong, nonatomic) NSArray<J_Mod, Optional> * Mods;
@property (assign, nonatomic) int Count;
@property (assign, nonatomic) int Start;

@end
