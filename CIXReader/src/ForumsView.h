//
//  ForumsView.h
//  CIXReader
//
//  Created by Steve Palmer on 15/08/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "ViewBaseView.h"
#import "TopicFolder.h"
#import "CRRoundImageView.h"
#import "CRView.h"

@interface ForumsView : ViewBaseView {
    IBOutlet CRView * mainView;
    IBOutlet NSImageView * forumImage;
    IBOutlet NSTextField * forumName;
    IBOutlet NSTextField * forumTitle;
    IBOutlet NSTextField * forumDescription;
    IBOutlet NSTextField * resignedText;
    IBOutlet NSTextField * forumLatestDate;
    IBOutlet NSButton * resignButton;
    IBOutlet NSButton * deleteButton;
    IBOutlet NSButton * participantsButton;
    IBOutlet NSButton * editButton;
    IBOutlet NSCollectionView * moderatorList;
    IBOutlet NSArrayController * arrayController;
    IBOutlet NSLayoutConstraint * resignedTextConstraint;
    
    TopicFolder * _currentFolder;
    DirForum * _forum;
    BOOL _didInitialise;
}

// Accessors
-(IBAction)handleResignButton:(id)sender;
-(IBAction)handleDeleteButton:(id)sender;
-(IBAction)handleEditButton:(id)sender;
-(IBAction)handleParticipantsButton:(id)sender;
@end
