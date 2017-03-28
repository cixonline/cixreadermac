//
//  APIRequest.h
//  CIXClient
//
//  Created by Steve Palmer on 17/09/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "JSONModel.h"

typedef enum {
    APIMethodGet,
    APIMethodPost
} APIRequestMethod;

/** The APIRequest class
 
 The APIRequest class is a singleton that exposes functions to create NSURLRequest
 objects for specific API requests. While the caller could create NSURLRequest objects
 manually, the APIRequest functions automate most of the work of creating a valid GET
 or POST request pre-initialised with queries or data and with the users credentials
 intialised in the request packet.
 */
@interface APIRequest : NSObject

// Accessors
+(BOOL)useBetaAPI;
+(void)setUseBetaAPI:(BOOL)flag;
+(const NSString *)apiBase;
+(NSURLRequest *)get:(NSString *)apiFunction;
+(NSURLRequest *)get:(NSString *)apiFunction withQuery:(NSString *)queryString;
+(NSURLRequest *)getWithCredentials:(NSString *)apiFunction username:(NSString *)username password:(NSString *)password;
+(NSURLRequest *)post:(NSString *)apiFunction withData:(id)data;
+(NSString *)responseTextFromData:(NSData *)data;
@end
