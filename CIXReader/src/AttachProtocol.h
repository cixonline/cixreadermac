//
//  AttachProtocol.h
//  CIXReader
//
//  Created by Steve Palmer on 15/01/2016.
//  Copyright © 2016 CIXOnline Ltd. All rights reserved.
//

@interface AttachProtocol : NSURLProtocol

// Accessors
+(NSString *)scheme;
+(void)registerProtocol;
@end
