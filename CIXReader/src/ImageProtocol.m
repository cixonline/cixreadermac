//
//  ImageProtocol.m
//  CIXReader
//
//  Created by Steve Palmer on 25/08/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "ImageProtocol.h"
#import "ImageExtensions.h"
#import "CIX.h"

@implementation ImageProtocol

/* This is the name of the protocol we handle here.
 */
+(NSString *)scheme
{
	return @"mugshot";
}

/* Our own class method.  We call this routine to handle registration
 * of our special protocol.  You should call this routine BEFORE any urls
 * specifying your special protocol scheme are presented to webkit.
 */
+(void)registerProtocol
{
	static BOOL inited = NO;
	if (!inited )
    {
		[NSURLProtocol registerClass:[ImageProtocol class]];
		inited = YES;
	}
}

/* Class method for protocol called by webview to determine if this
 * protocol should be used to load the request.
 */
+(BOOL)canInitWithRequest:(NSURLRequest *)theRequest
{
	NSString * theScheme = [[theRequest URL] scheme];
    NSString * theResource = [[theRequest URL] resourceSpecifier];
	if ([theScheme caseInsensitiveCompare: [ImageProtocol scheme]] != NSOrderedSame )
        return NO;
    if ([theResource hasPrefix:@"$"])
        return NO;
    return YES;
}

/* If canInitWithRequest returns true, then webKit will call your
 * canonicalRequestForRequest method so you have an opportunity to modify
 * the NSURLRequest before processing the request
 */
+(NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

/* Our main loading routine.  This is where we do most of our processing
 * for our class.  In this case, all we are doing is taking the path part
 * of the url and rendering it in 36 point system font as a jpeg file.  The
 * interesting part is that we create the jpeg entirely in memory and return
 * it back for rendering in the webView.
 */
-(void)startLoading
{
    id<NSURLProtocolClient> client = [self client];
    NSURLRequest *request = [self request];

	// Get the actual image name. This comes after the protocol part.
	NSString * username = [[request URL] resourceSpecifier];

    // Get the image. This may be varying dimensions so we need to resize it
    // to the standard dimensions.
    Mugshot * mugshot = [Mugshot mugshotForUser:username];
    NSImage * myImage = [mugshot.image resize:NSMakeSize(50, 50)];
    
    myImage = [myImage maskedCircularImageWithDiameter:50];
    
    // Retrieve the jfif data for the image
    NSData *data = [myImage JFIFData: 0.75];

    // Create the response record, set the mime type to jpeg
    NSURLResponse *response = [[NSURLResponse alloc] initWithURL:[request URL]
            MIMEType:@"image/jpeg" 
            expectedContentLength:-1 
            textEncodingName:nil];

    // Turn off caching for this response data */
    [client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    
    // Set the data in the response to our jfif data
    [client URLProtocol:self didLoadData:data];

    // Notify that we completed loading
    [client URLProtocolDidFinishLoading:self];
}

/* Called to stop loading or to abort loading.  We don't do anything special
 * here.
 */
-(void)stopLoading
{
}
@end

