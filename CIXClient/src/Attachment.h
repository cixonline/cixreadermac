//
//  Attachment.h
//  CIXClient
//
//  Created by Steve Palmer on 14/01/2016.
//  Copyright © 2016 CIXOnline Ltd. All rights reserved.
//

#import "TableBase.h"

@interface Attachment : TableBase

@property ID_type ID;
@property ID_type messageID;
@property NSString * filename;
@property NSString * encodedData;

// Accessors
+(NSArray *)attachmentsForMessage:(ID_type)messageID;
-(NSData *)data;
@end
