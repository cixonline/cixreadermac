//
//  ImageProtocol.h
//  CIXReader
//
//  Created by Steve Palmer on 25/08/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

@interface ImageProtocol : NSURLProtocol

// Accessors
+(NSString *)scheme;
+(void)registerProtocol;
@end
