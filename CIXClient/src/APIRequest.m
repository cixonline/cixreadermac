//
//  APIRequest.m
//  CIXClient
//
//  Created by Steve Palmer on 17/09/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "CIX.h"
#import "StringExtensions.h"
#import "ImageExtensions.h"

static const NSString * BetaAPIBase = @"https://betaapi.cixonline.com/v2.0/cix.svc/";
static const NSString * APIBase = @"https://api.cixonline.com/v2.0/cix.svc/";

static BOOL _useBetaAPI;
static const NSString * _apiBase;

@implementation APIRequest

/** Returns a Boolean value that indicates whether APIRequest uses the beta API
 
 @return Returns YES if APIRequest is configured to use the beta API.
 */
+(BOOL)useBetaAPI
{
    return _useBetaAPI;
}

/** Changes whether or not APIRequest uses the beta API.
 
 This value can be changed at any time but should ideally be done before the
 first APIRequest is made as otherwise undefined results can occur if the API
 server is switched in mid-transaction.
 
 @param flag Indicates whether to use the beta API. The default is NO.
 */
+(void)setUseBetaAPI:(BOOL)flag
{
    _useBetaAPI = flag;
    _apiBase = nil;
}

/** Return the CIX API server base URL
 
 @return Returns the API server base URL
 */
+(const NSString *)apiBase
{
    if (_apiBase == nil)
    {
        _apiBase = [self useBetaAPI] ? BetaAPIBase : APIBase;
        [LogFile.logFile writeLine:@"APIBase=%@", _apiBase];
    }
    return _apiBase;
}

/** Constructs an NSURLRequest to make a GET request to the API function with the 
    users current credentials.
 
  This method constructs an NSURLRequest to make a GET call to the CIX API server
  to call the specified function with the users current credentials. The request
  will be made using basic authentication.

 @param apiFunction The path of the API function, minus any extension
 @return Returns an NSURLRequest for the GET request or nil if there was an error
 */
+(NSURLRequest *)get:(NSString *)apiFunction
{
    return [APIRequest create:apiFunction username:CIX.username password:CIX.password method:APIMethodGet query:nil data:nil];
}

/** Constructs an NSURLRequest to make a GET request to the API function with the 
    users current credentials and query parameter.
 
 This method constructs an NSURLRequest to make a GET call to the CIX API server
 to call the specified function with the users current credentials. The request
 will be made using basic authentication.
 
 @param apiFunction The path of the API function, minus any extension
 @param queryString The query parameter to be passed to the API function
 @return Returns an NSURLRequest for the GET request or nil if there was an error
 */
+(NSURLRequest *)get:(NSString *)apiFunction withQuery:(NSString *)queryString
{
    return [APIRequest create:apiFunction username:CIX.username password:CIX.password method:APIMethodGet query:queryString data:nil];
}

/** Constructs an NSURLRequest to make a POST request to the API function with 
    the users current credentials and data.
 
 This method constructs an NSURLRequest to make a POST call to the CIX API server
 to call the specified function with the users current credentials and the given data.
 The request will be made using basic authentication.
 
 @param apiFunction The path of the API function, minus any extension
 @param data The data to be encoded and posted to the server
 @return Returns an NSURLRequest for the POST request or nil if there was an error
 */
+(NSURLRequest *)post:(NSString *)apiFunction withData:(id)data
{
    return [APIRequest create:apiFunction username:CIX.username password:CIX.password method:APIMethodPost query:nil data:data];
}

/** Constructs a NSURLRequest to make a GET request to the API function with the 
    specified credentials.
 
 This method constructs an NSURLRequest to make a call to the CIX API server
 to call the specified function with the specified credentials. The request
 will be made using basic authentication.
 
 @param apiFunction The path of the API function, minus any extension
 @param username The CIX login username
 @param password The CIX login password
 @return Returns an NSURLRequest for the request or nil if there was an error
 */
+(NSURLRequest *)getWithCredentials:(NSString *)apiFunction username:(NSString *)username password:(NSString *)password
{
    return [APIRequest create:apiFunction username:username password:password method:APIMethodGet query:nil data:nil];
}

/** Retrieve the raw response text from the response data
 
 This method parses a response data block returned by one of the NSURLConnection functions
 and returns the actual response text embedded in standardised form.
 
 @param data The response data block from an NSURLConnection call
 @return An NSString containing the parsed data, or nil if no response could be determined
 */
+(NSString *)responseTextFromData:(NSData *)data
{
    NSString * responseString = [[NSString alloc] initWithBytes:data.bytes length:data.length encoding:NSUTF8StringEncoding];
    if (responseString != nil)
        responseString = [responseString trimWithCharacter:'\"'];

    return responseString;
}

/* Internal core function that creates a NSURLRequest given a username, password, request method, 
 * optional query and optional data.
 */
+(NSURLRequest *)create:(NSString *)apiFunction
               username:(NSString *)username
               password:(NSString *)password
                 method:(APIRequestMethod)method
            query:(NSString *)query
                   data:(id)data
{
    if (username == nil || password == nil)
        return nil;
    
    NSURL * endPoint = [APIRequest makeURL:apiFunction withQuery:query];
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:endPoint];
    
    switch (method)
    {
        case APIMethodGet:
            [request setHTTPMethod: @"GET"];
            [request addValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
            [request addValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Accept"];
            break;
            
        case APIMethodPost:
            [request setHTTPMethod: @"POST"];
            if ([[data class] isSubclassOfClass:[JSONModel class]])
            {
                NSString * string = [data toJSONString];
                [request setHTTPBody:[string dataUsingEncoding:NSUTF8StringEncoding]];

                [request addValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
                [request addValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Accept"];
            }
            if ([[data class] isSubclassOfClass:[NSArray class]])
            {
                NSArray * jsonArray = [JSONModel arrayOfDictionariesFromModels:data];

                NSError *jsonError = nil;
                NSData * jsonData = [NSJSONSerialization dataWithJSONObject:jsonArray options:kNilOptions error:&jsonError];

                [request setHTTPBody:jsonData];
                
                [request addValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
                [request addValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Accept"];
            }
            if ([[data class] isSubclassOfClass:[NSString class]])
            {
                [request setHTTPBody:[data dataUsingEncoding:NSASCIIStringEncoding]];
                
                [request addValue:@"application/text" forHTTPHeaderField:@"Content-Type"];
            }
            if ([[data class] isSubclassOfClass:[ImageClass class]])
            {
                ImageClass * image = (ImageClass *)data;
                NSData * imageData = [image JFIFData:1.0];
                
                [request setHTTPBody:imageData];
                [request setValue:[NSString stringWithFormat:@"%d", (unsigned int)[imageData length]] forHTTPHeaderField:@"Content-Length"];
                
                [request addValue:@"image/jpeg" forHTTPHeaderField:@"Content-Type"];
            }
            break;
    }

    // Set the basic authentication header information
    NSString * authInfo = [NSString stringWithFormat:@"%@:%@", username, password];
    NSString * base64Data = [[authInfo dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
    authInfo = [NSString stringWithFormat:@"Basic %@", base64Data];
    
    [request addValue:authInfo forHTTPHeaderField:@"Authorization"];
    
    return request;
}

/* Construct a URL with the specified API function and optional query string. The
 * format, which is not passed as part of the apiFunction name, is always assumed to
 * be JSON. If we later support other formats (XML) then we'll need to pass that
 * through here.
 */
+(NSURL *)makeURL:(NSString *)apiFunction withQuery:(NSString *)queryString
{
    NSMutableString * urlString = [NSMutableString stringWithFormat:@"%@%@.json", [self apiBase], apiFunction];
    if (queryString != nil)
        [urlString appendFormat:@"?%@", [queryString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    return [NSURL URLWithString:urlString];
}
@end
