//
//  Attachment2.h
//  CIXClient
//
//  Created by Steve Palmer on 14/01/2016.
//  Copyright © 2016 CIXOnline Ltd. All rights reserved.
//

#import "JSONModel.h"

@protocol J_Attachment2
@end

@interface J_Attachment2 : JSONModel

@property (strong, nonatomic) NSString * EncodedData;
@property (strong, nonatomic) NSString * Filename;

@end
