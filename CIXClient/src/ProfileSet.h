//
//  ProfileSet.h
//  CIXClient
//
//  Created by Steve Palmer on 18/09/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "JSONModel.h"

@interface J_ProfileSet : JSONModel

@property (strong, nonatomic) NSString * Fname;
@property (strong, nonatomic) NSString * Sname;
@property (strong, nonatomic) NSString * Location;
@property (strong, nonatomic) NSString * Email;
@property (strong, nonatomic) NSString * Sex;
@property (assign, nonatomic) int Flags;

@end
