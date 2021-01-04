//
//  TopicView.h
//  CIXReader
//
//  Created by Steve Palmer on 13/10/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "ViewBaseView.h"
#import "TopicFolder.h"
#import "SmartFolder.h"
#import "ArticleView.h"
#import "CRTableView.h"
#import "StyleController.h"
#import "GoToController.h"

@interface TopicView : ViewBaseView<NSTableViewDelegate> {
    IBOutlet CRTableView * threadList;
    IBOutlet ArticleView * messageText;
    IBOutlet NSSplitView * splitter;
    IBOutlet NSButton * createMessageButton;
    IBOutlet NSView * textCanvas;
    IBOutlet NSView * emptyMessageView;
    IBOutlet NSView * loadingView;
    IBOutlet NSProgressIndicator * progressIndicator;
    IBOutlet NSMenu * sortMenu;

    NSMutableArray * _messages;
    NSFont * _cellFont;
    NSFont * _boldCellFont;
    FolderBase * _currentFolder;
    NSDateFormatter * _dateFormatter;
    StyleController * _currentStyleController;
    GoToController * _goToInputController;
    BOOL _didInitialise;
    BOOL _isFiltering;
    BOOL _showIgnored;
    BOOL _groupByConv;
    BOOL _collapseConv;
    BOOL _suspendFixup;
}

// Accessors
-(BOOL)scrollMessage;
-(IBAction)handleStartNewThread:(id)sender;
@end
