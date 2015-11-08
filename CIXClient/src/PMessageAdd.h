//
//  PMessageAdd.h
//  CIXClient
//
//  Created by Steve Palmer on 17/09/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "JSONModel.h"

@interface J_PMessageAdd : JSONModel

@property (strong, nonatomic) NSString * Body;
@property (strong, nonatomic) NSString * Recipient;
@property (strong, nonatomic) NSString * Subject;

@end
