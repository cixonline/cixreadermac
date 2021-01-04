//
//  ArticleView.h
//  CIXReader
//
//  Created by Steve Palmer on 25/08/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import <WebKit/WebKit.h>

@interface ArticleView : WebView <WebUIDelegate, WebPolicyDelegate> {
	NSString * _currentHTML;
    WebPreferences * _defaultWebPrefs;
    NSView * _overlayView;
}

// Public functions
-(void)clearHTML;
-(void)setHTML:(NSString *)htmlText;
-(void)setOverlayView:(NSView *)newOverlay;
-(void)clearOverlayView;
-(NSString *)selectedText;
-(BOOL)canScroll;
@end
