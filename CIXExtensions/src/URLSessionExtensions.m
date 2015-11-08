//
//  URLSessionExtensions.m
//  CIXExtensions
//
//  Created by Steve Palmer on 12/11/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "URLSessionExtensions.h"

@implementation NSURLSession (SynchronousTask)

+(NSData *)sendSynchronousDataTaskWithRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSData *data = nil;
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *taskData, NSURLResponse *taskResponse, NSError *taskError)
    {
        data = taskData;
        if (response)
            *response = taskResponse;
        if (error)
            *error = taskError;
        dispatch_semaphore_signal(semaphore);
    }] resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return data;
}
@end
