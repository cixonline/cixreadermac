//
//  MailView.h
//  CIXReader
//
//  Created by Steve Palmer on 29/08/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "ViewBaseView.h"
#import "ConversationCollection.h"
#import "MailFolder.h"
#import "ArticleView.h"
#import "StyleController.h"
#import "CRTableView.h"

@interface MailView : ViewBaseView <NSTableViewDelegate, NSTableViewDataSource> {
    IBOutlet CRTableView * messageTable;
    IBOutlet ArticleView * messageText;
    IBOutlet NSButton * createMessageButton;
    IBOutlet NSView * textCanvas;
    IBOutlet NSMenu * sortMenu;
    IBOutlet NSView * emptyMessageView;
    IBOutlet NSSplitView * splitter;
    
    NSMutableArray * _conversations;
    NSDateFormatter * _dateFormatter;
    MailFolder * _currentFolder;
    StyleController * _currentStyleController;
    BOOL _didInitialise;
}

// Accessors
-(IBAction)handleCreateMessage:(id)sender;
@end
