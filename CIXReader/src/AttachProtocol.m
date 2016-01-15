//
//  AttachProtocol.m
//  CIXReader
//
//  Created by Steve Palmer on 15/01/2016.
//  Copyright © 2016 CIXOnline Ltd. All rights reserved.
//

#import "AttachProtocol.h"
#import "Attachment.h"
#import "ImageExtensions.h"
#import "Cix.h"

@implementation AttachProtocol

/* This is the name of the protocol we handle here.
 */
+(NSString *)scheme
{
    return @"attach";
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
        [NSURLProtocol registerClass:[AttachProtocol class]];
        inited = YES;
    }
}

/* Class method for protocol called by webview to determine if this
 * protocol should be used to load the request.
 */
+(BOOL)canInitWithRequest:(NSURLRequest *)theRequest
{
    NSString * theScheme = [[theRequest URL] scheme];
    return ([theScheme caseInsensitiveCompare:[AttachProtocol scheme]] == NSOrderedSame);
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
    
    // Get the address part which is divided into a message ID followed
    // by an attachment number, separated by a ':'.
    NSString * address = [[request URL] resourceSpecifier];
    NSArray * parts = [address componentsSeparatedByString:@"/"];
    if (parts.count != 3)
        return;
    
    // Get the image. This may be varying dimensions so we need to resize it
    // to the standard dimensions.
    int topicID = [parts[0] intValue];
    NSInteger messageId = [parts[1] longLongValue];
    int attachmentIndex = [parts[2] intValue];
    
    Folder * topic = [[CIX folderCollection] folderByID:topicID];
    NSArray * attachments = [[[topic messages] messageByID:messageId] attachments];
    if (attachments != nil && attachmentIndex >= 0 && attachmentIndex < attachments.count)
    {
        Attachment * attach = attachments[attachmentIndex];
        NSImage * image = [[NSImage alloc] initWithData:attach.data];

        // Retrieve the jfif data for the image
        NSData *data = [image JFIFData:0.75];
        
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
}

/* Called to stop loading or to abort loading.  We don't do anything special
 * here.
 */
-(void)stopLoading
{
}
@end
