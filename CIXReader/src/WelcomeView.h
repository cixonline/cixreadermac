//
//  WelcomeView.h
//  CIXReader
//
//  Created by Steve Palmer on 08/10/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "ViewBaseView.h"
#import "CRView.h"
#import "ArticleView.h"

@interface WelcomeView : ViewBaseView<WebFrameLoadDelegate> {
    IBOutlet ArticleView * homePage;
    
    bool _didInitialise;
}
@end
