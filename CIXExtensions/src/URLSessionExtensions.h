//
//  URLSessionExtensions.h
//  CIXExtensions
//
//  Created by Steve Palmer on 12/11/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

@interface NSURLSession (SynchronousTask)
    +(NSData *)sendSynchronousDataTaskWithRequest:(NSURLRequest *)request
                                returningResponse:(__strong NSURLResponse **)response
                                            error:(__strong NSError **)error;
@end
