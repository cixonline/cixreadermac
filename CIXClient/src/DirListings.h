//
//  DirListings.h
//  CIXClient
//
//  Created by Steve Palmer on 25/09/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "JSONModel.h"

@protocol J_Listing
@end

@interface J_Listing : JSONModel

@property (strong, nonatomic) NSString * Cat;
@property (strong, nonatomic) NSString * Forum;
@property (assign, nonatomic) int Recent;
@property (strong, nonatomic) NSString * Sub;
@property (strong, nonatomic) NSString * Title;
@property (strong, nonatomic) NSString * Type;

@end

@interface J_DirListings : JSONModel

@property (strong, nonatomic) NSArray<J_Listing, Optional> * Forums;
@property (assign, nonatomic) int Count;
@property (assign, nonatomic) int Start;

@end
