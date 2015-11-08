//
//  URLSessionExtensions.h
//  CIXExtensions
//
//  Created by Steve Palmer on 12/11/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

@interface NSURLSession (SynchronousTask)
    +(NSData *)sendSynchronousDataTaskWithRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error;
@end
