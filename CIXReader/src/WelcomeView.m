//
//  WelcomeView.m
//  CIXReader
//
//  Created by Steve Palmer on 08/10/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "WelcomeView.h"
#import "AppDelegate.h"
#import "CIXThread.h"
#import "ImageProtocol.h"
#import "DateExtensions.h"
#import "StringExtensions.h"

@implementation WelcomeView

/* Initialise the welcome view.
 */
-(id)init
{
    return [super initWithNibName:@"WelcomeView" bundle:nil];
}

/* Load HTML for home page into the webkit.
 */
-(void)awakeFromNib
{
    if (!_didInitialise)
    {
        NSString * resourcePath = [[NSBundle mainBundle] resourcePath];
        NSString * homePagePath = [resourcePath stringByAppendingPathComponent:@"Home Page"];
        
        NSString * homePageFile = [homePagePath stringByAppendingPathComponent:@"Home.html"];
        NSString * htmlText = [NSString stringWithContentsOfFile:homePageFile usedEncoding:NULL error:NULL];

        // Substitute root of Resources
        NSString * fileHomePagePath = [@"file://" stringByAppendingPathComponent:homePagePath];
        htmlText = [htmlText stringByReplacingOccurrencesOfString:@"$Root$" withString:fileHomePagePath];
        
        // Register for notifications
        NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(handleOnlineUsersChanged:) name:MAOnlineUsersRefreshed object:nil];
        [nc addObserver:self selector:@selector(handleInterestingThreadsChanged:) name:MAInterestingThreadsRefreshed object:nil];
        [nc addObserver:self selector:@selector(handleMugshotChanged:) name:MAUserMugshotChanged object:nil];
        
        [ImageProtocol registerProtocol];
        
        [homePage setFrameLoadDelegate:self];
        [homePage setHTML:htmlText];
        _didInitialise = true;
    }
}

/* Make sure the main view is first responder so single key actions
 * will just work.
 */
-(BOOL)viewFromFolder:(FolderBase *)folder withAddress:(Address *)address options:(FolderOptions)options
{
    [[self.view window] makeFirstResponder:self.view];
    return NO;
}

/* Wait until the HTML frame is loaded before refreshing or we'll get a race
 * condition where the data arrives but there's nowhere to put it.
 */
-(void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    [CIX refreshOnlineUsers];
    [CIX.folderCollection refreshInterestingThreads];
}

/* Invoked when a mugshot has been refreshed from the server.
 */
-(void)handleMugshotChanged:(NSNotification *)nc
{
    [homePage setNeedsDisplay:YES];
}

/* Invoked when the list of online users has been changed.
 * Rebuild the HTML portion that lists the users
 */
-(void)handleOnlineUsersChanged:(NSNotification *)nc
{
    Response * resp = (Response *)nc.object;
    if (resp != nil && resp.errorCode == CCResponse_NoError)
    {
        NSMutableString * body = [NSMutableString stringWithString:@"<h2>Users who are online now</h2><br />"];
        
        DOMDocument *domDoc = [[homePage mainFrame] DOMDocument];
        DOMHTMLElement *container = (DOMHTMLElement *)[domDoc getElementById:@"onlineUsers"];
        
        // Make the div visible.
        DOMCSSStyleDeclaration *style = [container style];
        style.display = @"block";
        
        NSString * elementHTML = [container innerHTML];
        
        NSArray * users = (NSArray *)resp.object;
        int maxUsers = 10;
        for (NSString * user in users)
        {
            if (maxUsers-- == 0)
                break;
            NSMutableString * oneItem = [NSMutableString stringWithString:elementHTML];
            [oneItem replaceString:@"$User$" withString:user];
            [body appendString:oneItem];
        }
        
        [container setInnerHTML:body];
        [homePage setNeedsDisplay:YES];
    }
}

/* Invoked when the list of interesting threads has been
 * refreshed from the server.
 */
-(void)handleInterestingThreadsChanged:(NSNotification *)nc
{
    Response * resp = (Response *)nc.object;
    if (resp != nil && resp.errorCode == CCResponse_NoError)
    {
        NSMutableString * body = [NSMutableString stringWithString:@"<h2>Interesting Threads</h2><br />"];
        
        DOMDocument * domDoc = [[homePage mainFrame] DOMDocument];
        DOMHTMLElement * container = (DOMHTMLElement *)[domDoc getElementById:@"interestingThreads"];
        
        // Make the div visible.
        DOMCSSStyleDeclaration *style = [container style];
        style.display = @"block";
        
        NSString * elementHTML = [container innerHTML];
        
        NSArray * threads = (NSArray *)resp.object;
        for (CIXThread * thread in threads)
        {
            NSMutableString * oneItem = [NSMutableString stringWithString:elementHTML];
            [oneItem replaceString:@"$Author$" withString:thread.author];
            [oneItem replaceString:@"$Subject$" withString:[thread.body.firstNonBlankLine truncateByWordWithLimit:80]];
            [oneItem replaceString:@"$Link$" withString:[NSString stringWithFormat:@"%@/%@", thread.forum, thread.topic]];
            [oneItem replaceString:@"$RootID$" withString:[NSString stringWithFormat:@"%d", thread.remoteID]];
            [oneItem replaceString:@"$Date$" withString:[thread.date friendlyDescription]];
            [body appendString:oneItem];
        }
        
        [container setInnerHTML:body];
        [homePage setNeedsDisplay:YES];
    }
}

/* Respond to keyboard actions at the view.
 */
-(BOOL)handleKeyDown:(unichar)keyChar withFlags:(NSUInteger)flags
{
    return [(AppDelegate *)[NSApp delegate] handleKeyDown:keyChar withFlags:flags];
}

/* Return whether the view can action the specified Action ID.
 */
-(BOOL)canAction:(ActionID)actionID
{
    switch (actionID)
    {
        case ActionIDBiggerText:
        case ActionIDSmallerText:
            return YES;
            
        default:
            break;
    }
    return NO;
}

/* Carry out the specified Action ID.
 */
-(void)action:(ActionID)actionID
{
    switch (actionID)
    {
        case ActionIDSmallerText:
            [homePage makeTextSmaller:self];
            break;
            
        case ActionIDBiggerText:
            [homePage makeTextLarger:self];
            break;
            
        default:
            break;
    }
}
@end
