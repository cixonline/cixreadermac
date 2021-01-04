//
//  Response.h
//  CIXClient
//
//  Created by Steve Palmer on 09/10/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#define CCResponse_NoError                      0
#define CCResponse_Offline                      1
#define CCResponse_ServerError                  2
#define CCResponse_Busy                         5

#define CCResponse_NoSuchUser                   50
#define CCResponse_NoSuchForum                  51

#define CCResponse_JoinFailure_NoSuchForum      100
#define CCResponse_JoinFailure_Limited          102

#define CCResponse_ResignFailure_NoSuchForum    110
#define CCResponse_ResignFailure_Limited        111

#define CCResponse_PostFailure                  120

/** The Response class
 
 The Response class is used to collect the result of an API request for
 communication with the caller via notifications. Where a table method is
 documented as running asynchronously and notifying the caller via NSNotification
 events, the object field of the notification may be set to a Response object
 which provides additional details of the result of the method.
 */
@interface Response : NSObject

/** Generic object
 
 The object field contains a generic object whose value depends on the caller
 but is usually the object which was recently accessed. The value may be nil
 if the caller chooses not to provide any object data.
 
 @return A generic NSObject whose value depends on the caller
 */
@property id object;

/** Error code

 This field will be set to one of the documented CCResponse error codes
 depending on the result of the method.
 
 @return A unique error code containing the result of the method
 */
@property NSInteger errorCode;

// Accessors
+(Response *)responseWithObject:(id)object andError:(NSInteger)errorCode;
-(id)initWithObject:(id)object;
-(id)initWithObject:(id)object andError:(NSInteger)errorCode;
@end
