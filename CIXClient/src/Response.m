//
//  Response.m
//  CIXClient
//
//  Created by Steve Palmer on 09/10/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "Response.h"

@implementation Response

/** Create a Response object with the given object and error code
 
 The object value may be nil if the caller has no useful data to provide.
 The error code should be one of the documented CCResponse error codes.

 @param object A generic object
 @param errorCode An unique error code
 @returns A Response object initialised with the object and error code
 */
+(Response *)responseWithObject:(id)object andError:(NSInteger)errorCode
{
    return [[Response alloc] initWithObject:object andError:errorCode];
}

/** Create a Response object with the given object

 The object value may be nil if the caller has no useful data to provide.
 The error code will default to CCResponse_NoError.

 @param object A generic object
 @returns A Response object initialised with the object
 */
-(id)initWithObject:(id)object
{
    if ((self = [super init]) != nil)
    {
        self.object = object;
        self.errorCode = CCResponse_NoError;
    }
    return self;
}

/** Create a Response object with the given object and error code
 
 The object value may be nil if the caller has no useful data to provide.
 The error code should be one of the documented CCResponse error codes.

 @param object A generic object
 @param errorCode An unique error code
 @returns A Response object initialised with the object and error code
 */
-(id)initWithObject:(id)object andError:(NSInteger)errorCode
{
    if ((self = [super init]) != nil)
    {
        self.object = object;
        self.errorCode = errorCode;
    }
    return self;
}
@end
