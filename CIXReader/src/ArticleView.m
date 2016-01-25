//
//  ArticleView.m
//  CIXReader
//
//  Created by Steve Palmer on 25/08/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "CIX.h"
#import "ArticleView.h"
#import "Preferences.h"
#import "AppDelegate.h"

@implementation ArticleView

/* The designated instance initialiser.
 */
-(id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect]) != nil)
	{
		// Init our vars
		_currentHTML = nil;

        // Handle minimum font size & using of JavaScript
        _defaultWebPrefs = [self preferences];
        [_defaultWebPrefs setStandardFontFamily:@"Arial"];
        [_defaultWebPrefs setDefaultFontSize:12];
        [_defaultWebPrefs setPrivateBrowsingEnabled:NO];
        [_defaultWebPrefs setJavaScriptEnabled:YES];

        [self setPolicyDelegate:self];
        [self setUIDelegate:self];
        
		// enlarge / reduce the text size according to user's setting
        Preferences * prefs = [Preferences standardPreferences];
        [self setTextSizeMultiplier:[prefs textSizeMultiplier]];
	}
	return self;
}

/* Don't accept stuff dragged into the article view.
 */
-(BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{ 
	return NO;
}

/* Return whether the webview can be scrolled.
 */
-(BOOL)canScroll
{
    NSScroller * scroll = self.mainFrame.frameView.documentView.enclosingScrollView.verticalScroller;
    return scroll.knobProportion > 0.0 && scroll.knobProportion < 1.0 && scroll.floatValue < 1.0;
}

/* Set the overlay view which is displayed on top of the
 * article view.
 */
-(void)setOverlayView:(NSView *)newOverlay
{
    [self clearOverlayView];

    [newOverlay setTranslatesAutoresizingMaskIntoConstraints:NO];
    [newOverlay setHidden:NO];
    [self addSubview:newOverlay];
    
    // Create constraints for the width and height to allow the centering to work
    // from something.
    NSDictionary * views = NSDictionaryOfVariableBindings(newOverlay);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
                          [NSString stringWithFormat:@"H:[newOverlay(%f)]", newOverlay.frame.size.width]
                            options:0
                            metrics:nil
                              views:views]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
                          [NSString stringWithFormat:@"V:[newOverlay(%f)]", newOverlay.frame.size.height]
                            options:0
                            metrics:nil
                              views:views]];

    // Manually add the constraints for centering vertically and horizontally
    NSLayoutConstraint * centerX = [NSLayoutConstraint constraintWithItem:newOverlay
                                     attribute:NSLayoutAttributeCenterX
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self
                                     attribute:NSLayoutAttributeCenterX
                                    multiplier:1
                                      constant:0];
    NSLayoutConstraint * centerY = [NSLayoutConstraint constraintWithItem:newOverlay
                                      attribute:NSLayoutAttributeCenterY
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:self
                                      attribute:NSLayoutAttributeCenterY
                                     multiplier:1
                                       constant:0];
    [self addConstraint:centerX];
    [self addConstraint:centerY];

    [self.window layoutIfNeeded];
    _overlayView = newOverlay;
}

-(void)clearOverlayView
{
    if (_overlayView != nil)
        [_overlayView removeFromSuperview];
}

/* Loads the web view with the HTML text for a blank page.
 */
-(void)clearHTML
{
	_currentHTML = @"<HTML></HTML>";
	[[self mainFrame] loadHTMLString:_currentHTML baseURL:nil];
}

/* Loads the web view with the specified HTML text.
 */
-(void)setHTML:(NSString *)htmlText
{
	// If the current HTML is the same as the new HTML then we don't need to
	// do anything here. This will stop the view from spurious redraws of the same
	// article after a refresh.
	if ([_currentHTML isEqualToString:htmlText])
		return;
	
	// Remember the current html string.
	_currentHTML = [[NSString alloc] initWithString:htmlText];
	
	[[self mainFrame] loadHTMLString:htmlText baseURL:nil];
}

/* Here is where we handle special keys when the web view
 * has the focus so we can do custom things.
 */
-(void)keyDown:(NSEvent *)theEvent
{
    if ([[theEvent characters] length] == 1)
    {
        unichar keyChar = [[theEvent characters] characterAtIndex:0];
        AppDelegate * app = (AppDelegate *)[NSApp delegate];
        if ([app handleKeyDown:keyChar withFlags:[theEvent modifierFlags]])
            return;
        
        //Don't go back or forward in article view.
        if (([theEvent modifierFlags] & NSCommandKeyMask) && ((keyChar == NSLeftArrowFunctionKey) || (keyChar == NSRightArrowFunctionKey)))
            return;
    }
    [super keyDown:theEvent];
}

/* makeTextSmaller
 */
-(IBAction)makeTextSmaller:(id)sender
{
	[super makeTextSmaller:sender];
	[[Preferences standardPreferences] setTextSizeMultiplier:[self textSizeMultiplier]];
}

/* makeTextLarger
 */
-(IBAction)makeTextLarger:(id)sender
{
	[super makeTextLarger:sender];
	[[Preferences standardPreferences] setTextSizeMultiplier:[self textSizeMultiplier]];
}

/* Return the selected text in the article view, or an empty string if no
 * text has been selected.
 */
-(NSString *)selectedText
{
    DOMRange * ff = [self selectedDOMRange];
    NSString * markup = [ff markupString];
    
    if (markup == nil)
        return @"";
    
    NSMutableString * marki = [NSMutableString stringWithString:markup];
    
    // Restore quote characters by inserting a '> ' in front of every blockquote
    // opening tag.
    NSError * error = NULL;

    NSString * linkPattern = @"(<blockquote.*?>)(.*</blockquote>)";
    NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:linkPattern options:NSRegularExpressionCaseInsensitive error:&error];
    [regex replaceMatchesInString:marki options:0 range:NSMakeRange(0, [marki length]) withTemplate:@"$1&gt;&nbsp;$2"];

    NSData * data = [marki dataUsingEncoding: NSUTF8StringEncoding];
    NSNumber * n = [NSNumber numberWithUnsignedInteger: NSUTF8StringEncoding];
    NSDictionary * options = [NSDictionary dictionaryWithObject:n forKey: NSCharacterEncodingDocumentOption];
    NSAttributedString * as = [[NSAttributedString alloc] initWithHTML:data options:options documentAttributes:nil];
    return [as string];
}

/* Called by the web view to get our policy on handling navigation actions. We want links clicked in the
 * web view to open in the external browser.
 */
-(void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation
       request:(NSURLRequest *)request
         frame:(WebFrame *)frame
decisionListener:(id<WebPolicyDecisionListener>)listener
{
    int navType = [[actionInformation valueForKey:WebActionNavigationTypeKey] intValue];
    
    if (navType == WebNavigationTypeLinkClicked)
    {
        [listener ignore];
        
        // Trap cix: and cixuser: style URLs here and let AppDelegate handle them
        if ([request.URL.scheme isEqualToString:@"cix"] || [request.URL.scheme isEqualToString:@"cixuser"])
        {
            AppDelegate * app = (AppDelegate *)[NSApp delegate];
            [app setAddress:[request.URL absoluteString]];
            return;
        }

        NSWorkspaceLaunchOptions lOptions = (NSWorkspaceLaunchDefault | NSWorkspaceLaunchDefault);
        [[NSWorkspace sharedWorkspace] openURLs:@[ request.URL ]
                        withAppBundleIdentifier:NULL
                                        options:lOptions
                 additionalEventParamDescriptor:NULL
                              launchIdentifiers:NULL];
        return;
    }
    [listener use];
}
@end
