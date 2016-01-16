//
//  PostMessage2Response.h
//  CIXClient
//
//  Created by Steve Palmer on 16/01/2016.
//  Copyright © 2016 CIXOnline Ltd. All rights reserved.
//

#import "JSONModel.h"

@protocol J_PostMessage2Response
@end

@interface J_PostMessage2Response : JSONModel

@property (strong, nonatomic) NSString * Body;
@property (assign, nonatomic) int MessageNumber;
@property (strong, nonatomic) NSString * Response;

@end
