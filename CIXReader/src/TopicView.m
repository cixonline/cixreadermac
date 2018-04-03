//
//  TopicView.m
//  CIXReader
//
//  Created by Steve Palmer on 13/10/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "CIX.h"
#import "TopicView.h"
#import "MessageCellView.h"
#import "StringExtensions.h"
#import "DateExtensions.h"
#import "SplitViewExtensions.h"
#import "Preferences.h"
#import "AppDelegate.h"
#import "MessageEditor.h"
#import "MailEditor.h"
#import "ParticipantsListController.h"

static NSImage * unreadImage = nil;
static NSImage * starImage = nil;
static NSImage * readlockedImage = nil;
static NSImage * threadClosedImage = nil;
static NSImage * threadOpenImage = nil;

@implementation TopicView

/* Initialise the topic view.
 */
-(id)init
{
    if ((self = [super initWithNibName:@"TopicView" bundle:nil]) != nil)
        [super initSorting:Sort_Date ascending:YES];

    return self;
}

-(void)awakeFromNib
{
    if (!_didInitialise)
    {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateStyle:NSDateFormatterMediumStyle];

        if (unreadImage == nil)
            unreadImage = [NSImage imageNamed:@"unread.tiff"];
        if (starImage == nil)
            starImage = [NSImage imageNamed:@"star.tiff"];
        if (readlockedImage == nil)
            readlockedImage = [NSImage imageNamed:@"readlock.tiff"];
        if (threadClosedImage == nil)
            threadClosedImage = [NSImage imageNamed:@"threadClosed.png"];
        if (threadOpenImage == nil)
            threadOpenImage = [NSImage imageNamed:@"threadOpen.png"];

        NSColor * backColor = [NSColor colorWithCalibratedRed:(244.0 / 255) green:(244.0 / 255) blue:(244.0 / 255) alpha:0.8];
        textCanvas.layer.backgroundColor = backColor.CGColor;

        Preferences * prefs = [Preferences standardPreferences];
        _currentStyleController = [[StyleController alloc] initForStyle:[prefs displayStyle]];
        
        [self setArticleListFont];
        
        [threadList setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
        [threadList setDoubleAction:@selector(doubleClickAction:)];
        [threadList setTarget:self];

        AppDelegate * app = (AppDelegate *)[NSApp delegate];
        [threadList setMenu:app.articleMenu];

        [splitter setViewRects:[prefs topicViewLayout]];
        
        _showIgnored = [prefs showIgnored];
        _groupByConv = [prefs groupByConv];
        _collapseConv = [prefs collapseConv];
        
        // Register for notifications
        NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(handleArticleListFontChange:) name:MA_Notify_ArticleListFontChange object:nil];
        [nc addObserver:self selector:@selector(handleFolderRefreshed:) name:MAFolderRefreshed object:nil];
        [nc addObserver:self selector:@selector(handleFolderFixed:) name:MAFolderFixed object:nil];
        [nc addObserver:self selector:@selector(handleFolderRefreshStarted:) name:MAFolderRefreshStarted object:nil];
        [nc addObserver:self selector:@selector(handleStyleChange:) name:MA_Notify_StyleChange object:nil];
        [nc addObserver:self selector:@selector(handleArticleViewChange:) name:MA_Notify_ArticleViewChange object:nil];
        [nc addObserver:self selector:@selector(handleThreadPaneChange:) name:MA_Notify_ThreadPaneChanged object:nil];
        [nc addObserver:self selector:@selector(handleMessageChanged:) name:MAMessageChanged object:nil];
        [nc addObserver:self selector:@selector(handleMessageAdded:) name:MAMessageAdded object:nil];
        [nc addObserver:self selector:@selector(handleFolderChanged:) name:MAUserMugshotChanged object:nil];
        [nc addObserver:self selector:@selector(handleMessageDeleted:) name:MAMessageDeleted object:nil];
        [nc addObserver:self selector:@selector(handleFolderChanged:) name:MAFolderChanged object:nil];

        _didInitialise = YES;
    }
}

/* Save the splitter position
 */
-(void)splitViewDidResizeSubviews:(NSNotification *)notification
{
    [[Preferences standardPreferences] setTopicViewLayout:[splitter viewRects]];
}

/* Display the view for the specified folder.
 */
-(BOOL)viewFromFolder:(FolderBase *)folder withAddress:(Address *)address options:(FolderOptions)options
{
    if (folder.viewForFolder == AppViewTopic)
    {
        // Refresh the thread list if the folder has changed, or, for search folders, if the
        // search string has changed. Return instantly if the list is empty.
        if ([folder isKindOfClass:SearchFolder.class])
        {
            SearchFolder * searchFolder = (SearchFolder *)folder;
            _currentFolder = folder;

            if (![_currentStyleController.highlightString isEqualToString:searchFolder.searchString])
            {
                _isFiltering = YES;
                _currentStyleController.highlightString = searchFolder.searchString;

                [threadList deselectAll:self];
                [self sortConversations:NO];
            }
        }
        else if (_currentFolder != folder || (options & FolderOptionsClearFilter))
        {
            _currentFolder = folder;
            _isFiltering = NO;
            _currentStyleController.highlightString = nil;
            
            [threadList deselectAll:self];
            [self sortConversations:NO];
        }

        if (_messages.count == 0)
        {
            // If no messages then get some from the server if possible.
            if (address != nil && [address.scheme isEqualToString:@"cix"])
                _currentFolder.lastIndex = [address.data intValue];
            
            if (![_currentFolder refresh])
                [self showEmptyMessage];
            return NO;
        }

        if (options & FolderOptionsClearFilter)
            options &= ~FolderOptionsClearFilter;

        if (address != nil && [address.scheme isEqualToString:@"cix"])
        {
            NSInteger selectedID = [address.data intValue];
            if (![self goToMessage:selectedID])
                [self setInitialSelection];
            
            if (address.unread)
            {
                Message * message = [self selectedMessage];
                [message markUnread];
            }
        }
        else if (options == 0)
            [self setInitialSelection];
        else
        {
            NSInteger row = threadList.searchRow;
            if (row < 0)
                row = -1;
            else
            {
                Message * message = _messages[row];
                if (message.unread)
                    [message markRead];
            }
            if (![self firstUnreadAfterRow:row withOptions:options])
            {
                threadList.searchRow = 0;
                return NO;
            }
        }
    }
    [self.view.window makeFirstResponder:threadList];
    return YES;
}

/* Locate and select the first unread message after the given row.
 */
-(BOOL)firstUnreadAfterRow:(NSInteger)row withOptions:(FolderOptions)options
{
    while (++row < _messages.count)
    {
        Message * message = _messages[row];
        
        if ([self isCollapsed:message] && message.unreadChildren > 0)
            [self expandThread:message];

        if ((options & FolderOptionsPriority) == FolderOptionsPriority)
        {
            if (message.priority && message.unread)
            {
                [threadList setSelectedRow:row];
                break;
            }
        }
        else if ((options & FolderOptionsNextUnread) == FolderOptionsNextUnread && message.unread)
        {
            if ((options & FolderOptionsRoot) == FolderOptionsRoot)
            {
                while (message.commentID > 0 && row > 0)
                    message = _messages[--row];
            }
            [threadList setSelectedRow:row];
            break;
        }
    }
    return (row != _messages.count);
}

-(BOOL)scrollMessage
{
    NSScroller * scroll = messageText.mainFrame.frameView.documentView.enclosingScrollView.verticalScroller;
    if (!([scroll knobProportion] == 1.0 || [scroll floatValue] == 1.0))
    {
        [messageText scrollPageDown:self];
        return YES;
    }
    return NO;
}

/* When going to the folder manually (and not via nextUnread), then display the first
 * unread if there is one, otherwise display the last message visited or, failing that,
 * go to the most recent message.
 */
-(void)setInitialSelection
{
    if (![self firstUnreadAfterRow:0 withOptions:FolderOptionsNextUnread])
    {
        if (_currentFolder.lastIndex == 0)
            [threadList setSelectedRow:_sortAscending ? (_messages.count - 1) : 0];
        else
            [self goToMessage:_currentFolder.lastIndex];
    }
}

/* Handle a double-click to edit a message.
 */
-(void)doubleClickAction:(id)sender
{
    if ([self canAction:ActionIDEditMessage])
        [self action:ActionIDEditMessage];
}

/* Return whether the view can action the specified Action ID.
 */
-(BOOL)canAction:(ActionID)actionID
{
    switch (actionID)
    {
        case ActionIDPrint:
        case ActionIDShowProfile:
        case ActionIDMarkReadLock:
        case ActionIDMarkStar:
        case ActionIDMarkPriority:
        case ActionIDMarkIgnore:
        case ActionIDReplyByMail:
        case ActionIDBlock:
        case ActionIDMarkThreadRead: {
            Message * message = [self selectedMessage];
            return message != nil && !message.isPseudo;
        }

        case ActionIDMarkRead: {
            Message * message = [self selectedMessage];
            return message != nil && !message.readLocked && !message.isPseudo;
        }
            
        case ActionIDExpandCollapseThread: {
            Message * message = [self selectedMessage];
            return message != nil && [self isExpandable:message];
        }
            
        case ActionIDScrollMessage:
            return [messageText canScroll];
            
        case ActionIDDelete:
        case ActionIDWithdraw:  {
            Message * message = [self selectedMessage];
            Folder * folder = [CIX.folderCollection folderByID:message.topicID];
            Folder * forumFolder = folder.parentFolder;

            DirForum * forum = [CIX.directoryCollection forumByName:forumFolder.name];
            return message.isDraft || message.isMine || forum.isModerator;
        }

        case ActionIDNewMessage: {
            if ([_currentFolder isKindOfClass:TopicFolder.class])
            {
                TopicFolder * topicFolder = (TopicFolder *)_currentFolder;
                Folder * forumFolder = topicFolder.folder.parentFolder;
                DirForum * forum = [CIX.directoryCollection forumByName:forumFolder.name];
                return forum.isModerator || !IsReadOnly(topicFolder.folder);
            }
            return NO;
        }

        case ActionIDParticipants:
            return _currentFolder.ID > 0;

        case ActionIDBiggerText:
        case ActionIDSmallerText:
            return YES;
            
        case ActionIDEditMessage: {
            Message * message = [self selectedMessage];
            return message.isPseudo;
        }

        case ActionIDGoto:
            return _messages.count > 0;
            
        case ActionIDReplyWithQuote:
        case ActionIDReply: {
            Message * message = [self selectedMessage];
            Folder * folder = [CIX.folderCollection folderByID:message.topicID];

            Folder * forumFolder = folder.parentFolder;
            DirForum * forum = [CIX.directoryCollection forumByName:forumFolder.name];
            return message != nil && !message.isPseudo && (forum.isModerator || !IsReadOnly(folder));
        }

        case ActionIDGotoPreviousRoot: {
            NSInteger index = threadList.selectedRow;
            return index > 0;
        }
            
        case ActionIDGotoNextRoot: {
            NSInteger index = threadList.selectedRow;
            return index < _messages.count;
        }
            
        case ActionIDGotoOriginal: {
            Message * message = [self selectedMessage];
            return message != nil && message.commentID != 0;
        }
            
        default:
            break;
    }
    return NO;
}

/* Return the toolbar image name for the specified action where the actionID
 * toolbar image can vary.
 */
-(NSString *)imageForAction:(ActionID)actionID
{
    switch (actionID)
    {
        case ActionIDMarkStar: {
            Message * message = [self selectedMessage];
            return (message.starred ? @"tbUnflag" : @"tbFlag");
        }
            
        case ActionIDMarkReadLock: {
            Message * message = [self selectedMessage];
            return (message.readLocked ? @"tbReadUnlock" : @"tbReadLock");
        }
            
        default:
            break;
    }
    return nil;
}

/* Return the menu title for the specified action where the actionID
 * title can vary.
 */
-(NSString *)titleForAction:(ActionID)actionID
{
    switch (actionID)
    {
        case ActionIDMarkReadLock: {
            Message * message = [self selectedMessage];
            return (message.readLocked ? NSLocalizedString(@"Clear Read Lock", nil) : NSLocalizedString(@"Set Read Lock", nil));
        }

        case ActionIDMarkRead: {
            Message * message = [self selectedMessage];
            return (message.unread ? NSLocalizedString(@"As Read", nil) : NSLocalizedString(@"As Unread", nil));
        }

        case ActionIDMarkStar: {
            Message * message = [self selectedMessage];
            return (message.starred ? NSLocalizedString(@"Clear Flag", nil) : NSLocalizedString(@"Flag", nil));
        }
            
        case ActionIDMarkPriority: {
            Message * message = [self selectedMessage];
            return (message.priority ? NSLocalizedString(@"As Normal", nil) : NSLocalizedString(@"As Priority", nil));
        }
            
        case ActionIDMarkIgnore: {
            Message * message = [self selectedMessage];
            return (message.ignored ? NSLocalizedString(@"As Unignored", nil) : NSLocalizedString(@"As Ignored", nil));
        }
            
        case ActionIDWithdraw: {
            Message * message = [self selectedMessage];
            return ((message.isDraft || message.postPending) ? NSLocalizedString(@"Delete", nil) : NSLocalizedString(@"Withdraw", nil));
        }
            
        default:
            break;
    }
    return nil;
}

/* Carry out the specified Action ID.
 */
-(void)action:(ActionID)actionID
{
    switch (actionID)
    {
        case ActionIDReplyWithQuote:
        case ActionIDReply: {
            Message * parent = [self selectedMessage];

            Folder * folder = [CIX.folderCollection folderByID:parent.topicID];
            BOOL ownerCommentsOnly = (folder.flags & FolderFlagsOwnerCommentsOnly);
            if (ownerCommentsOnly && !parent.isMine)
            {
                [self action:ActionIDReplyByMail];
                return;
            }
            
            if (!parent.isPseudo)
            {
                if (parent.unread)
                    [parent markRead];
                
                Message * newMessage = [Message new];
                
                newMessage.commentID = parent.remoteID;
                newMessage.rootID = (parent.commentID == 0) ? parent.remoteID : parent.rootID;
                newMessage.topicID = parent.topicID;
                newMessage.unread = YES;
                
                if (actionID == ActionIDReplyWithQuote)
                    newMessage.body = parent.quotedBody;
                else
                {
                    NSString * selectedText = messageText.selectedText;
                    if (!IsEmpty(selectedText))
                        newMessage.body = selectedText.quotedString;
                }
                
                MessageEditor * msgWindow = [[MessageEditor alloc] initWithMessage:newMessage addSignature:YES];
                [msgWindow showWindow:self];
                [[msgWindow window] makeKeyAndOrderFront:self];
            }
            break;
        }

        case ActionIDReplyByMail: {
            Message * message = [self selectedMessage];
            if (!message.isPseudo)
            {
                MailEditor * msgWindow = [[MailEditor alloc] initWithMessage:message];
                [msgWindow showWindow:self];
                [[msgWindow window] makeKeyAndOrderFront:self];
            }
            break;
        }
            
        case ActionIDExpandCollapseThread: {
            Message * message = [self selectedMessage];
            if (message != nil)
                [self expandCollapseThread:message];
            break;
        }
            
        case ActionIDParticipants:
            if (_currentFolder.ID > 0)
            {
                TopicFolder * topicFolder = (TopicFolder *)_currentFolder;
                Folder * forumFolder = topicFolder.folder.parentFolder;
                DirForum * forum = [CIX.directoryCollection forumByName:forumFolder.name];
                
                ParticipantsListController * partList = [[ParticipantsListController alloc] initWithForum:forum];
                NSWindow * partListWindow = [partList window];
                
                [NSApp runModalForWindow:partListWindow];
                [NSApp endSheet:partListWindow];
                [partListWindow orderOut: self];
            }
            break;

        case ActionIDScrollMessage:
            [messageText scrollPageDown:self];
            break;
            
        case ActionIDNewMessage: {
            if (_currentFolder.ID > 0)
            {
                Message * newMessage = [Message new];
                
                newMessage.topicID = _currentFolder.ID;
                newMessage.unread = YES;

                MessageEditor * msgWindow = [[MessageEditor alloc] initWithMessage:newMessage addSignature:YES];
                [msgWindow showWindow:self];
                [[msgWindow window] makeKeyAndOrderFront:self];
            }
            break;
        }

        case ActionIDMarkThreadRead: {
            Message * message = [self selectedMessage];
            [message markReadThread];
            break;
        }
            
        case ActionIDBlock: {
            Message * message = [self selectedMessage];
            NSAlert * alert = [[NSAlert alloc] init];
            
            [alert addButtonWithTitle:NSLocalizedString(@"Yes", nil)];
            [alert addButtonWithTitle:NSLocalizedString(@"No", nil)];
            [alert setMessageText:NSLocalizedString(@"Block User", nil)];
            [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"All existing messages and any new messages from %@ will automatically be marked as read. Are you sure?", nil), message.author]];
            [alert setAlertStyle:NSWarningAlertStyle];

            NSModalResponse returnCode = [alert runModal];
            if (returnCode == NSAlertFirstButtonReturn)
            {
                [[CIX ruleCollection] block:message.author];
                [self refreshMessage:message];
            }
            break;
        }
            
        case ActionIDDelete:
        case ActionIDWithdraw:  {
            Message * message = [self selectedMessage];
            if (message.isDraft || message.postPending)
                [self deleteMessage:message];
            else
                [self withdrawMessage:message];
            break;
        }

        case ActionIDSmallerText:
            [messageText makeTextSmaller:self];
            break;
            
        case ActionIDBiggerText:
            [messageText makeTextLarger:self];
            break;
            
        case ActionIDPrint:
            [self handlePrint:self];
            break;
            
        case ActionIDGoto:
            [self handleGoToMessage:self];
            break;
            
        case ActionIDGotoOriginal: {
            Message * message = [self selectedMessage];
            if (message != nil)
                [(AppDelegate *)[NSApp delegate] setAddress:[self addressFromMessage:message withID:message.commentID]];
            break;
        }
            
        case ActionIDGotoNextRoot:
        case ActionIDGotoPreviousRoot: {
            NSInteger index = threadList.selectedRow;
            NSInteger direction = (actionID == ActionIDGotoNextRoot) ? 1 : -1;

            index += direction;
            while (index >= 0 && index < _messages.count)
            {
                Message * message = _messages[index];
                if (message.level == 0)
                {
                    [(AppDelegate *)[NSApp delegate] setAddress:[self addressFromMessage:message withID:message.remoteID]];
                    break;
                }
                index += direction;
            }
            break;
        }
            
        case ActionIDEditMessage: {
            Message * message = [self selectedMessage];
            if (message.isPseudo)
            {
                MessageEditor * msgWindow = [[MessageEditor alloc] initWithMessage:message addSignature:NO];
                [msgWindow showWindow:self];
                [[msgWindow window] makeKeyAndOrderFront:self];
            }
            break;
        }
            
        case ActionIDMarkRead:
            [self handleMarkRead:self];
            break;
            
        case ActionIDMarkStar:
            [self handleMarkStar:self];
            break;
            
        case ActionIDMarkPriority:
            [self handleMarkPriority:self];
            break;
            
        case ActionIDMarkIgnore:
            [self handleMarkIgnore:self];
            break;
            
        case ActionIDMarkReadLock:
            [self handleMarkReadLock:self];
            break;
            
        case ActionIDShowProfile: {
            Message * message = [self selectedMessage];
            if (message != nil)
            {
                NSString * address = [NSString stringWithFormat:@"cixuser:%@", message.author];
                [(AppDelegate *)[NSApp delegate] setAddress:address];
            }
            break;
        }
            
        default:
            break;
    }
}

/* Construct a Sort menu for this view.
 */
-(NSMenu *)sortMenu
{
    return sortMenu;
}

/* Assign the collection of messages to the mutable _messages array. Note that this is
 * a bit of a hack due to the test for Sort_Conversation and the fact that we have different
 * interfaces in MessagesCollection.
 * TODO: Clean this up!
 */
-(void)assignArrayOfMessages
{
    if (_groupByConv && [_currentFolder isKindOfClass:TopicFolder.class])
    {
        TopicFolder * topicFolder = (TopicFolder *)_currentFolder;

        _messages = [NSMutableArray arrayWithArray:[topicFolder.folder.messages roots]];
        [_messages sortUsingDescriptors:@[ [self sortDescriptorForOrder:_currentSortOrder ]]];
        
        if (!_collapseConv)
        {
            for (NSInteger index = _messages.count - 1; index >= 0; index--)
            {
                Message * message = _messages[index];
                NSArray * children = [topicFolder.folder.messages childrenOfMessage:message];
                NSIndexSet * indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index + 1, children.count)];
                [_messages insertObjects:children atIndexes:indexes];
            }
        }
    }
    else
        _messages = [NSMutableArray arrayWithArray:[_currentFolder items]];
    threadList.searchRow = -1;
}

/* Invoked when the user enters something in the search filter.
 */
-(void)filterViewByString:(NSString *)searchString
{
    Message * selectedMessage = [self selectedMessage];
    bool hasFilter = !IsEmpty(searchString);
    bool tempCollapseConv = _collapseConv;
    
    _collapseConv = false;
    [self assignArrayOfMessages];
    _collapseConv = tempCollapseConv;
    
    if (hasFilter)
    {
        NSPredicate * bPredicate =[NSPredicate predicateWithFormat:@"(SELF.author contains[cd] %@) OR (SELF.body contains[cd] %@)", searchString, searchString];
        [_messages filterUsingPredicate:bPredicate];
    }
    
    _currentStyleController.highlightString = searchString;
    _isFiltering = hasFilter;
    
    [threadList reloadData];
    
    // If the selected message isn't in the result set, default to selecting the first one
    if ([_messages indexOfObject:selectedMessage] == NSNotFound && _messages.count > 0)
        selectedMessage = _messages[0];
    
    [self restoreSelection:selectedMessage];
}

/* Sort the conversations using the specified ordering.
 */
-(void)sortConversations:(BOOL)update
{
    Message * selectedMessage = [self selectedMessage];
    [self assignArrayOfMessages];
    
    // Take this opportunity to do a fixup on the folder
    if (_currentFolder.ID > 0 && !_suspendFixup)
    {
        TopicFolder * topicFolder = (TopicFolder *)_currentFolder;
        [topicFolder.folder fixup];
    }
    
    // Filter out all ignored messages
    if (!_showIgnored)
    {
        NSMutableArray * messagesToRemove = [NSMutableArray array];
        for (Message * message in _messages)
        {
            if (message.ignored)
                [messagesToRemove addObject:message];
        }
        [_messages removeObjectsInArray:messagesToRemove];
    }
    
    if (!_groupByConv)
        [_messages sortUsingDescriptors:@[ [self sortDescriptorForOrder:_currentSortOrder ]]];
    [threadList reloadData];
    
    if (update)
        [self restoreSelection:selectedMessage];

    [super sortConversations:update];
}

/* Called when the user changes the folder font and/or size in the Preferences
 */
-(void)handleArticleListFontChange:(NSNotification *)notification
{
    [self setArticleListFont];
    [self refreshList];
}

/* Return the current selected message
 */
-(Message *)selectedMessage
{
    NSInteger selectedRow = [threadList selectedRow];
    return (selectedRow >= 0 && selectedRow < _messages.count) ? _messages[selectedRow] : nil;
}

/* Restore the selection to the specified message
 */
-(void)restoreSelection:(Message *)message
{
    if (_messages.count == 0)
        [self showEmptyMessage];
    else
    {
        if (message != nil)
        {
            NSInteger row = [_messages indexOfObject:message];
            if (row != NSNotFound)
                [threadList setSelectedRow:row];
            else
            {
                if ([self isCollapsed:message.root])
                {
                    [self expandThread:message.root];
                    row = [_messages indexOfObject:message];
                    if (row != NSNotFound)
                        [threadList setSelectedRow:row];
                }
            }
        }
    }
}

/* Return a sort descriptor for the specified order.
 */
-(NSSortDescriptor *)sortDescriptorForOrder:(NSInteger)order
{
    NSString * keyName;
    SEL sel = NULL;
    switch (_currentSortOrder)
    {
        case Sort_Author:
            keyName = @"author";
            sel = @selector(localizedCompare:);
            break;
            
        case Sort_Date:
            keyName = @"date";
            sel = @selector(compare:);
            break;
            
        case Sort_Subject:
            keyName = @"subject";
            sel = @selector(localizedCompare:);
            break;
            
        default:
            NSAssert(false, @"Invalid _currentSortOrder");
            break;
    }
    return [NSSortDescriptor sortDescriptorWithKey:keyName ascending:_sortAscending selector:sel];
}

/* Folder contents have changed so redraw the list while preserving the
 * selection and the scroll offset.
 */
-(void)handleFolderChanged:(NSNotification *)notification
{
    NSRect scrollRect = [[threadList superview] bounds];
    [self refreshList];
    [[threadList superview] setBoundsOrigin:scrollRect.origin];
}

/* Refresh the list, preserving the selection.
 */
-(void)refreshList
{
    Message * savedMessage = [self selectedMessage];
    [threadList reloadData];
    [self restoreSelection:savedMessage];
}

/* Handle a folder fixup. We need to make sure we don't do recursive
 * fixups on the same folder!
 */
-(void)handleFolderFixed:(NSNotification *)notification
{
    _suspendFixup = true;
    [self handleFolderRefreshed:notification];
    _suspendFixup = false;
}

/* Respond to the MAFolderRefreshed notification. Make sure this is a notification
 * for the folder being displayed before doing anything as this notification is sent for
 * all folders being refreshed from the server.
 */
-(void)handleFolderRefreshed:(NSNotification *)notification
{
    Response * response = (Response *)notification.object;
    if (response.errorCode == CCResponse_NoError)
    {
        Folder * folder = response.object;
        if (_currentFolder.ID == folder.ID)
        {
            [messageText clearOverlayView];
            if (response.errorCode == CCResponse_NoError)
            {
                [self sortConversations:YES];

                if (_messages.count == 0)
                    [self showEmptyMessage];
                
                if (threadList.selectedRow == -1)
                    [self setInitialSelection];
            }
        }
    }
}

/* Respond to the notification that a folder refresh has started.
 * Display the spinning progress indicator.
 */
-(void)handleFolderRefreshStarted:(NSNotification *)notification
{
    Folder * folder = notification.object;
    if (_currentFolder.ID == folder.ID && _messages.count == 0)
        [self showLoading];
}

/* Handle a message being deleted by removing it from the list and
 * moving the selection to the next or previous message.
 */
-(void)handleMessageDeleted:(NSNotification *)notification
{
    Message * message = notification.object;
    if ([_messages containsObject:message])
        [self removeMessage:message];
}

/* Handle a message being added by reloading the list.
 */
-(void)handleMessageAdded:(NSNotification *)notification
{
    Message * message = notification.object;
    if (message.topicID == _currentFolder.ID)
        [self sortConversations:YES];
}

/* A message in this topic view has changed. We first make sure that it
 * is still valid in the current view and, if not, remove it. Otherwise
 * we refresh the message.
 */
-(void)handleMessageChanged:(NSNotification *)notification
{
    Response * response = notification.object;
    Message * message = response.object;
    [self refreshMessage:message];
}

/* Find the specified message in the list and refresh the row, along with
 * the message pane if necessary.
 */
-(void)refreshMessage:(Message *)message
{
    NSUInteger rowIndex = [_messages indexOfObject:message];
    if (rowIndex != NSNotFound)
    {
        if (![_currentFolder canContain:message])
        {
            [self removeMessage:message];
            return;
        }
        [threadList reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
    }
    if (message == [self selectedMessage])
        [self showSelectedMessage];
}

/* Invoke the New Message handler when the user clicks the "Start New Thread" button.
 */
-(IBAction)handleStartNewThread:(id)sender
{
    [self action:ActionIDNewMessage];
}

/* Remove the specified emssage from the collection and move the selection to
 * the next or previous message.
 */
-(void)removeMessage:(Message *)message
{
    NSInteger selectedRow = [threadList selectedRow];
    BOOL deletingCurrent = (selectedRow != -1) && (message == _messages[selectedRow]);
    
    [_messages removeObject:message];
    [self refreshList];
    
    if (deletingCurrent)
    {
        if (selectedRow == [_messages count])
            --selectedRow;
        if (selectedRow < 0)
            [self showEmptyMessage];
        else
            [threadList setSelectedRow:selectedRow];
    }
}

/* Withdraw the specified message. The message is assumed to be allowed
 * to be withdrawn.
 */
-(void)withdrawMessage:(Message *)message
{
    NSAlert * alert = [[NSAlert alloc] init];
    
    [alert addButtonWithTitle:NSLocalizedString(@"Yes", nil)];
    [alert addButtonWithTitle:NSLocalizedString(@"No", nil)];
    [alert setMessageText:NSLocalizedString(@"Withdraw", nil)];
    [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"Do you want to withdraw message %d?", nil), message.remoteID]];
    
    if ([alert runModal] == NSAlertFirstButtonReturn)
        [message withdraw];
}

/* Delete the specified message. The message is assumed to be
 * a draft or post pending and prior checking is done.
 */
-(void)deleteMessage:(Message *)message
{
    Folder * folder = [CIX.folderCollection folderByID:message.topicID];
    [folder.messages delete:message];
}

/* Print the current message in the message window.
 */
-(void)handlePrint:(id)sender
{
    NSPrintInfo * printInfo = [NSPrintInfo sharedPrintInfo];
    NSPrintOperation * printOp;
    
    [printInfo setVerticallyCentered:NO];
    printOp = [NSPrintOperation printOperationWithView:messageText.mainFrame.frameView.documentView printInfo:printInfo];
    [printOp runOperation];
}

/* Toggle the current selected message as read or unread. If the selected
 * message is a collapsed root then mark the whole thread instead.
 */
-(void)handleMarkRead:(id)sender
{
    NSInteger currentSelectedRow = [threadList selectedRow];
    if (currentSelectedRow >= 0)
    {
        Message * message = _messages[currentSelectedRow];
        if ([self isCollapsed:message])
        {
            if (message.unread)
                [message markReadThread];
            else
                [message markUnreadThread];
        }
        else
        {
            if (message.unread)
                [message markRead];
            else
                [message markUnread];
        }
    }
}

/* Toggle the read lock on the selected message.
 */
-(void)handleMarkReadLock:(id)sender
{
    NSInteger currentSelectedRow = [threadList selectedRow];
    if (currentSelectedRow >= 0)
    {
        Message * message = _messages[currentSelectedRow];
        if (message.readLocked)
            [message clearReadLock];
        else
            [message markReadLock];
    }
}

/* Toggle the current selected message as starred.
 */
-(void)handleMarkStar:(id)sender
{
    NSInteger currentSelectedRow = [threadList selectedRow];
    if (currentSelectedRow >= 0)
    {
        Message * message = _messages[currentSelectedRow];
        if (message.starred)
            [message removeStar];
        else
            [message addStar];
    }
}

/* Toggle the priority on the selected message
 */
-(void)handleMarkPriority:(id)sender
{
    NSInteger currentSelectedRow = [threadList selectedRow];
    if (currentSelectedRow >= 0)
    {
        Message * message = _messages[currentSelectedRow];
        if (message.priority)
            [message removePriority];
        else
            [message setPriority];
    }
}

/* Toggle whether the selected message is marked ignored.
 */
-(void)handleMarkIgnore:(id)sender
{
    NSInteger currentSelectedRow = [threadList selectedRow];
    if (currentSelectedRow >= 0)
    {
        Message * message = _messages[currentSelectedRow];
        if (message.ignored)
            [message removeIgnore];
        else
            [message setIgnore];
    }
}

/* Handle the Go To command
 */
-(void)handleGoToMessage:(id)sender
{
    if (_goToInputController == nil)
        _goToInputController = [GoToController new];
    [[NSApp mainWindow] beginSheet:_goToInputController.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSModalResponseOK)
        {
            [self->_goToInputController.window orderOut:self];
            
            NSInteger messageNumber = self->_goToInputController.value;
            if (![self goToMessage:self->_goToInputController.value]) {
                NSAlert * alert = [[NSAlert alloc] init];
                
                [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
                [alert setMessageText:NSLocalizedString(@"No Such Message", nil)];
                [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"Message %@ not found in this topic", nil), @(messageNumber)]];

                [alert runModal];
            }
        }
    }];
}

/* Expand or collapse the specified message.
 */
-(void)expandCollapseThread:(Message *)message
{
    if ([self isExpanded:message.root])
        [self collapseThread:message];
    else
        [self expandThread:message];
}

/* Return whether the specified message can be expanded.
 */
-(BOOL)isExpandable:(Message *)message
{
    return message.hasChildren && _groupByConv;
}

/* Return whether the specified message is collapsed.
 */
-(BOOL)isCollapsed:(Message *)message
{
    return message.level == 0 && message.hasChildren && _groupByConv && ![self isExpanded:message];
}

/* Return whether the specified message is already expanded.
 */
-(BOOL)isExpanded:(Message *)root
{
    if (root.level == 0)
    {
        NSUInteger index = [_messages indexOfObject:root];
        if (index != NSNotFound && index < _messages.count - 1)
        {
            Message * nextMessage = _messages[++index];
            if (nextMessage.level > 0)
                return true;
        }
    }
    return false;
}

/* Collapse the specified root message.
 */
-(void)collapseThread:(Message *)message
{
    Message * root = message.root;
    NSUInteger index = [_messages indexOfObject:root];
    NSUInteger count = _messages.count;
    if (index != NSNotFound && index < count - 1 && _currentFolder.ID > 0)
    {
        ++index;
        while (index < _messages.count && ((Message *)_messages[index]).level > 0)
            [_messages removeObjectAtIndex:index];
    }
    if (count != _messages.count)
    {
        [self refreshList];
        [self goToMessage:root.remoteID];
    }
}

/* Expand the specified root message
 */
-(void)expandThread:(Message *)message
{
    if (message.level == 0)
    {
        NSUInteger index = [_messages indexOfObject:message];
        NSUInteger count = _messages.count;
        if (index != NSNotFound && _currentFolder.ID > 0)
        {
            TopicFolder * topicFolder = (TopicFolder *)_currentFolder;
            NSArray * children = [topicFolder.folder.messages childrenOfMessage:message];
            NSIndexSet * indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index + 1, children.count)];
            [_messages insertObjects:children atIndexes:indexes];
        }
        if (count != _messages.count)
            [self refreshList];
    }
}

/* Scroll to and display the message whose remote ID is the given value.
 */
-(BOOL)goToMessage:(NSInteger)value
{
    NSInteger selectedIndex;
    for (selectedIndex = 0; selectedIndex < _messages.count; ++selectedIndex)
    {
        Message * message = _messages[selectedIndex];
        if (message.remoteID == value)
            break;
    }
    if (selectedIndex < _messages.count)
    {
        [threadList setSelectedRow:selectedIndex];
        return YES;
    }
    if (_currentFolder.ID >= 0 && _collapseConv)
    {
        TopicFolder * topicFolder = (TopicFolder *)_currentFolder;
        Message * message = [topicFolder.folder.messages messageByID:value];
        
        if (message != nil)
        {
            if ([self isCollapsed:message.root])
            {
                [self expandThread:message.root];
                [threadList setSelectedRow:[_messages indexOfObject:message]];
                return true;
            }
        }
    }

    return NO;
}

/* Show the empty thread list view.
 * Hide the "Create New Thread" button if the folder doesn't permit new messages to be created here.
 */
-(void)showEmptyMessage
{
    [messageText clearHTML];
    [createMessageButton setHidden:![self canAction:ActionIDNewMessage]];
    [messageText setOverlayView:emptyMessageView];
}

/* Show the loading view with the progress indicator.
 */
-(void)showLoading
{
    [messageText clearHTML];
    [messageText setOverlayView:loadingView];
    [progressIndicator startAnimation:self];
}

/* Updates the article pane when the active display style has been changed.
 */
-(void)handleStyleChange:(NSNotification *)notification
{
    Preferences * prefs = [Preferences standardPreferences];
    _currentStyleController = [[StyleController alloc] initForStyle:[prefs displayStyle]];
    [self showSelectedMessage];
}

/* Respond to preference changes that modify the article view.
 */
-(void)handleArticleViewChange:(NSNotification *)notification
{
    [self showSelectedMessage];
}

/* A thread pane setting changed so we need to rebuild the whole list.
 */
-(void)handleThreadPaneChange:(NSNotification *)notification
{
    Preferences * prefs = [Preferences standardPreferences];
    _showIgnored = [prefs showIgnored];
    _groupByConv = [prefs groupByConv];
    _collapseConv = [prefs collapseConv];
    [self sortConversations:YES];
}

-(void)showSelectedMessage
{
    Message * message = [self selectedMessage];
    if (message == nil)
        [self showEmptyMessage];
    else
    {
        // Save our last selection so we can restore it when we visit
        // this folder again.
        _currentFolder.lastIndex = message.remoteID;
        
        [messageText clearOverlayView];
        [messageText setHTML:[_currentStyleController styledTextForCollection:@[ message ]]];
    }
}

/* Return the current view and selected item as an address.
 */
-(NSString *)address
{
    NSInteger currentSelectedRow = [threadList selectedRow];
    int selectedID = 0;
    
    if (currentSelectedRow > -1)
    {
        Message * message = _messages[currentSelectedRow];
        selectedID = message.remoteID;
        return [self addressFromMessage:message withID:selectedID];
    }
    return _currentFolder.address;
}

-(NSString *)addressFromMessage:(Message *)message withID:(int)value
{
    Folder * topic = [CIX.folderCollection folderByID:message.topicID];
    Folder * forum = [topic parentFolder];
    return [NSString stringWithFormat:@"cix:%@/%@:%d", forum.name, topic.name, value];
}

/* Creates or updates the fonts used by the article list. The folder
 * list isn't automatically refreshed afterward - call reloadData for that.
 */
-(void)setArticleListFont
{
    int height;
    
    Preferences * prefs = [Preferences standardPreferences];
    _cellFont = [NSFont fontWithName:[prefs articleListFont] size:[prefs articleListFontSize]];
    _boldCellFont = [[NSFontManager sharedFontManager] convertWeight:YES ofFont:_cellFont];
    
    height = [[(AppDelegate *)[NSApp delegate] layoutManager] defaultLineHeightForFont:_cellFont];
    [threadList setRowHeight:height * 2 + 10];
    [threadList setIntercellSpacing:NSMakeSize(10, 2)];
}

/* Return the count in the current list of messages in the table.
 */
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [_messages count];
}

/* Handle the selection changing in the table view.
 * Note: we have to sync searchRow with selectedRow ourselves.
 */
-(void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    [threadList setSearchRow:threadList.selectedRow];
    [self showSelectedMessage];
    
    if (threadList.selectedRow >= 0)
    {
        bool isUnread = [self selectedMessage].unread;
        [(AppDelegate *)[NSApp delegate] addBacktrack:self.address withUnread:isUnread];
    }
}

/* Respond to keyboard actions at the tableview.
 */
-(BOOL)tableView:(CRTableView *)tableView handleKeyDown:(unichar)keyChar withFlags:(NSUInteger)flags
{
    return [(AppDelegate *)[NSApp delegate] handleKeyDown:keyChar withFlags:flags];
}

/* Render the view for each column of the table. There's just one column so this does the
 * whole row.
 */
-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    Message * message = _messages[row];
    MessageCellView * result = [tableView makeViewWithIdentifier:@"summaryCell" owner:nil];
    if (result != nil)
    {
        Mugshot * mugshot = [Mugshot mugshotForUser:message.author];
        
        BOOL canThread = (_groupByConv && !_isFiltering && _currentFolder.ID > 0);

        int cap = tableView.frame.size.width - 350;
        result.spacerWidth.constant = canThread ? MIN(14 * message.level, cap) : 0;
        
        NSString * dateString = [[message.date GMTBSTtoUTC] friendlyDescription];
        if (dateString == nil)
            dateString = [NSDateFormatter localizedStringFromDate:[message.date fromLocalDate] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
 
        result.mugshot.image = mugshot.image;
        result.author.stringValue = SafeString(message.author);
        result.date.stringValue = SafeString(dateString);
        result.subject.stringValue = SafeString([message subject]);
        
        NSMutableString * idString = [NSMutableString stringWithString:message.isPseudo ? @"Draft" : [@(message.remoteID) stringValue]];
        if (IsSmartFolder(_currentFolder))
        {
            Folder * topic = [CIX.folderCollection folderByID:message.topicID];
            Folder * forum = [topic parentFolder];
            [idString appendFormat:@" in %@ ∙ %@", forum.name, topic.displayName];
        }
        result.remoteID.stringValue = SafeString(idString);

        NSFont * itemFont = (message.commentID == 0) ? _boldCellFont : _cellFont;
        result.author.font = itemFont;
        result.date.font = itemFont;
        result.subject.font = itemFont;
        result.remoteID.font = itemFont;
        
        NSColor * textColor = message.ignored ? [NSColor disabledControlTextColor] : [NSColor textColor];
        result.remoteID.textColor = textColor;
        result.date.textColor = textColor;
        result.subject.textColor = textColor;
        result.author.textColor = (!message.ignored && message.priority) ? [NSColor redColor] : textColor;
        
        NSImageView * nextImage = result.image1;
        result.image1.image = nil;
        result.image2.image = nil;
        
        if (!canThread)
            result.expanderWidth.constant = 0;
        else
        {
            result.expanderWidth.constant = 12;
            if (message.level == 0 && message.hasChildren)
                result.expander.image = [self isCollapsed:message] ? threadClosedImage : threadOpenImage;
            else
                result.expander.image = nil;
        }
        
        if (message.readLocked)
        {
            nextImage.target = self;
            nextImage.action = @selector(handleMarkReadLock:);
            nextImage.image = readlockedImage;
            nextImage = result.image2;
        }
        else if (message.unread)
        {
            nextImage.target = self;
            nextImage.action = @selector(handleMarkRead:);
            nextImage.image = unreadImage;
            nextImage = result.image2;
        }
        
        if (message.starred)
        {
            nextImage.target = self;
            nextImage.action = @selector(handleMarkStar:);
            nextImage.image = starImage;
        }
    }
    return result;
}

/* Called to initiate a drag from the thread list
 */
-(BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard*)pboard
{
    [pboard declareTypes:@[ NSStringPboardType, CR_PBoardType_MessageList ] owner:self];

    NSDateFormatter * dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"ddMMMyyyy HH:MM"];
    
    // Get all the messages that are being dragged
    NSMutableString * newtext = [[NSMutableString alloc] init];
    NSMutableArray * messageList = [NSMutableArray array];
    
    for (NSUInteger i = indexes.firstIndex; i <= indexes.lastIndex; i = [indexes indexGreaterThanIndex:i])
    {
        Message * message = _messages[i];
        
        Folder * topic = [CIX.folderCollection folderByID:message.topicID];
        Folder * forum = [topic parentFolder];

        [newtext appendFormat:@"***COPIED FROM: >>>%@/%@ %d ", forum.name, topic.name, message.remoteID];
        [newtext appendFormat:@"%@(%ld)", message.author, message.body.length];
        [newtext appendFormat:@"%@ ", [dateFormat stringFromDate:message.date]];
 
        if (message.commentID > 0)
            [newtext appendFormat:@"c%d ", message.commentID];

        [newtext appendString:@"\n"];
        [newtext appendString:message.body];
        [newtext appendString:@"\n"];

        NSMutableDictionary * articleDict = [NSMutableDictionary dictionary];
        articleDict[@"TopicID"] = @(message.topicID);
        articleDict[@"MessageID"] = @(message.remoteID);
        [messageList addObject:articleDict];
    }
    
    // Put string on the pasteboard for external drops.
    [pboard setString:newtext forType:NSStringPboardType];
    [pboard setPropertyList:messageList forType:CR_PBoardType_MessageList];
    return YES;
}
@end
