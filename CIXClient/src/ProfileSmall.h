//
//  ProfileSmall.h
//  CIXClient
//
//  Created by Steve Palmer on 18/09/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "JSONModel.h"

@interface J_ProfileSmall : JSONModel

@property (strong, nonatomic) NSString * Email;
@property (strong, nonatomic) NSString * FirstOn;
@property (assign, nonatomic) int Flags;
@property (strong, nonatomic) NSString * Fname;
@property (strong, nonatomic) NSString * LastOn;
@property (strong, nonatomic) NSString * LastPost;
@property (strong, nonatomic) NSString * Location;
@property (strong, nonatomic) NSString * Sex;
@property (strong, nonatomic) NSString * Sname;
@property (strong, nonatomic) NSString * Uname;

@end
