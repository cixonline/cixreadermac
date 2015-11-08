//
//  SendMail.h
//  CIXClient
//
//  Created by Steve Palmer on 17/11/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "JSONModel.h"

@interface J_SendMail : JSONModel

@property (strong, nonatomic) NSString * Text;
@property (strong, nonatomic) NSString * HTML;

@end
