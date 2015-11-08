//
//  MailView.h
//  CIXReader
//
//  Created by Steve Palmer on 29/08/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "MailView.h"
#import "MailCellView.h"
#import "StringExtensions.h"
#import "DateExtensions.h"
#import "SplitViewExtensions.h"
#import "AppDelegate.h"
#import "ImageProtocol.h"
#import "MailEditor.h"
#import "Preferences.h"
#import "CIX.h"

static NSImage * unreadImage = nil;
static NSImage * replyImage = nil;
static NSImage * errorImage = nil;

@implementation MailView

/* Initialise the view with the default sort order for the
 * session.
 */
-(id)init
{
    if ((self = [super initWithNibName:@"MailView" bundle:nil]) != nil)
    {
        [super initSorting:Sort_Date ascending:NO];
        _didInitialise = NO;
    }
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
        if (replyImage == nil)
            replyImage = [NSImage imageNamed:@"reply.tiff"];
        if (errorImage == nil)
            errorImage = [NSImage imageNamed:@"error.tiff"];
        
        NSColor * backColor = [NSColor colorWithCalibratedRed:(244.0 / 255) green:(244.0 / 255) blue:(244.0 / 255) alpha:0.8];
        textCanvas.layer.backgroundColor = backColor.CGColor;

        Preferences * prefs = [Preferences standardPreferences];
        _currentStyleController = [[StyleController alloc] initForStyle:[prefs displayStyle]];
        
        [splitter setViewRects:[prefs mailViewLayout]];
        
        NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(handleConversationDeleted:) name:MAConversationDeleted object:nil];
        [nc addObserver:self selector:@selector(handleConversationAdded:) name:MAConversationAdded object:nil];
        [nc addObserver:self selector:@selector(handleMugshotUpdated:) name:MAUserMugshotChanged object:nil];
        [nc addObserver:self selector:@selector(handleStyleChange:) name:MA_Notify_StyleChange object:nil];
        [nc addObserver:self selector:@selector(handleArticleViewChange:) name:MA_Notify_ArticleViewChange object:nil];
        [nc addObserver:self selector:@selector(handleConversationChanged:) name:MAConversationChanged object:nil];
        
        [ImageProtocol registerProtocol];
        _didInitialise = YES;
    }
}

/* Save the splitter position
 */
-(void)splitViewDidResizeSubviews:(NSNotification *)notification
{
    [[Preferences standardPreferences] setMailViewLayout:[splitter viewRects]];
}

/* Display the view for the specified folder. The folder is assumed to be a
 * MessageFolder, otherwise this does nothing.
 */
-(BOOL)viewFromFolder:(MailFolder *)folder withAddress:(Address *)address options:(FolderOptions)options
{
    if (folder.viewForFolder == AppViewMail)
    {
        if (folder != _currentFolder)
        {
            _currentFolder = folder;
            [self reloadView];
        }
        if (address != nil && [address.scheme isEqualToString:@"cixmailbox"])
        {
            ID_type selectedID = [address.data longLongValue];
            
            int selectedIndex;
            for (selectedIndex = 0; selectedIndex < _conversations.count; ++selectedIndex)
            {
                Conversation * conversation = _conversations[selectedIndex];
                if (conversation.ID == selectedID)
                    break;
            }
            if (selectedIndex == _conversations.count)
                selectedIndex = 0;
            [messageTable setSelectedRow:selectedIndex];

            if (address.unread)
            {
                Conversation * conv = [self selectedMessage];
                [conv markUnread];
            }
            
            [self.view.window makeFirstResponder:messageTable];
            return YES;
        }
        if (options == 0 && [messageTable selectedRow] < 0)
            [self setInitialSelection];
        else
        {
            NSInteger row = messageTable.searchRow;
            if (row < 0 || (options & FolderOptionsReset))
                row = 0;
            else
            {
                Conversation * conversation = _conversations[row];
                if (conversation.unread)
                    [conversation markRead];
            }
            if (![self firstUnreadAfterRow:row withOptions:options])
            {
                messageTable.searchRow = 0;
                return NO;
            }
        }
    }
    [self.view.window makeFirstResponder:messageTable];
    return YES;
}

/* Locate and select the first unread mail message after the given row.
 */
-(BOOL)firstUnreadAfterRow:(NSInteger)row withOptions:(FolderOptions)options
{
    while (row < _conversations.count)
    {
        Conversation * conversation = _conversations[row];
        if ((options & FolderOptionsNextUnread) == FolderOptionsNextUnread && conversation.unread)
        {
            [messageTable setSelectedRow:row];
            break;
        }
        row++;
    }
    return (row != _conversations.count);
}

/* Set the initial selection when entering the inbox view for the first time.
 */
-(void)setInitialSelection
{
    if (![self firstUnreadAfterRow:0 withOptions:FolderOptionsNextUnread])
        [messageTable setSelectedRow:_sortAscending ? _conversations.count - 1 : 0];
}

/* Reload the current view.
 */
-(void)reloadView
{
    _conversations = [NSMutableArray arrayWithArray:[_currentFolder items]];
    [self sortConversations:YES];
}

/* Return whether the view can action the specified Action ID.
 */
-(BOOL)canAction:(ActionID)actionID
{
    switch (actionID)
    {
        case ActionIDReply:
        case ActionIDDelete:
        case ActionIDWithdraw:
        case ActionIDShowProfile:
        case ActionIDPrint:
        case ActionIDMarkRead:
            return [messageTable selectedRow] != -1;
            
        case ActionIDBiggerText:
        case ActionIDSmallerText:
            return YES;
            
        case ActionIDScrollMessage:
            return [messageText canScroll];
            
        default:
            break;
    }
    return NO;
}

/* Return the menu title for the specified action where the actionID
 * title can vary.
 */
-(NSString *)titleForAction:(ActionID)actionID
{
    if (actionID == ActionIDMarkRead)
    {
        Conversation * conversation = [self selectedMessage];
        return (conversation.unread ? NSLocalizedString(@"As Read", nil) : NSLocalizedString(@"As Unread", nil));
    }
    if (actionID == ActionIDWithdraw)
        return NSLocalizedString(@"Delete", nil);
    return nil;
}

/* Carry out the specified Action ID.
 */
-(void)action:(ActionID)actionID
{
    switch (actionID)
    {
        case ActionIDReply: {
            NSInteger currentSelectedRow = [messageTable selectedRow];
            Conversation * conversation = _conversations[currentSelectedRow];
        
            MailEditor * msgWindow = [[MailEditor alloc] initWithConversation:conversation];
            [msgWindow showWindow:self];
            [[msgWindow window] makeKeyAndOrderFront:self];
            break;
        }
            
        case ActionIDScrollMessage:
            [messageText scrollPageDown:self];
            break;
            
        case ActionIDShowProfile: {
            Conversation * conversation = _conversations[messageTable.selectedRow];
            NSString * address = [NSString stringWithFormat:@"cixuser:%@", conversation.author];
            [(AppDelegate *)[NSApp delegate] setAddress:address];
            break;
        }

        case ActionIDSmallerText:
            [messageText makeTextSmaller:self];
            break;
            
        case ActionIDBiggerText:
            [messageText makeTextLarger:self];
            break;
            
        case ActionIDWithdraw:
        case ActionIDDelete: {
            Conversation * conversation = _conversations[messageTable.selectedRow];
            [conversation markDelete];
            break;
        }
            
        case ActionIDMarkRead:
            [self handleMarkRead:self];
            break;
            
        case ActionIDPrint:
            [self handlePrint:self];
            break;
            
        default:
            break;
    }
}

/* Returns YES if the scheme is one we can handle.
 */
-(BOOL)handles:(NSString *)scheme
{
    return [scheme isEqualToString:@"cixmailbox"];
}

/* Return the current view and selected item as an address. The
 * format is cixmailbox:id where ID is the remote address of the current
 * conversation being displayed. If no conversation is selected then
 * the return value is 0.
 */
-(NSString *)address
{
    NSInteger currentSelectedRow = [messageTable selectedRow];
    ID_type selectedID = 0;
    
    if (currentSelectedRow > -1)
    {
        Conversation * conversation = _conversations[currentSelectedRow];
        selectedID = conversation.ID;
    }
    return [NSString stringWithFormat:@"cixmailbox:inbox:%lld", selectedID];
}

/* Handle a conversation changed.
 */
-(void)handleConversationChanged:(NSNotification *)notification
{
    Conversation * selectedMessage = [self selectedMessage];
    [self reloadView];
    [self restoreSelection:selectedMessage];
}

/* Handle a conversation added in the collection
 * We don't know if the new conversation fits into the current filtered view being displayed so
 * just reload the view.
 */
-(void)handleConversationAdded:(NSNotification *)notification
{
    Conversation * selectedMessage = [self selectedMessage];
    [self reloadView];
    [self restoreSelection:selectedMessage];
}

/* Handle a conversation deletion in the collection
 */
-(void)handleConversationDeleted:(NSNotification *)notification
{
    Conversation * conversation = (Conversation *)[notification object];
    
    NSInteger selectedRow = [messageTable selectedRow];
    BOOL deletingCurrent = (selectedRow != -1) && (conversation == _conversations[selectedRow]);
    
    [_conversations removeObject:conversation];
    [self refreshList];
    
    if (deletingCurrent)
    {
        if (selectedRow == _conversations.count)
            --selectedRow;
        if (selectedRow < 0)
            [self showEmptyMessage];
        else
            [messageTable setSelectedRow:selectedRow];
    }
}

/* A user's mugshot has been updated. Refresh any rows that may
 * be showing that mugshot.
 */
-(void)handleMugshotUpdated:(NSNotification *)notification
{
    Response * response = (Response *)notification.object;
    if (response.errorCode == CCResponse_NoError)
        [self refreshList];
}

-(IBAction)handleCreateMessage:(id)sender
{
    MailEditor * msgWindow = [[MailEditor alloc] init];
    [msgWindow showWindow:self];
    [[msgWindow window] makeKeyAndOrderFront:self];
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

/* Toggle the current selected message as read or unread.
 */
-(void)handleMarkRead:(id)sender
{
    NSInteger currentSelectedRow = [messageTable selectedRow];
    if (currentSelectedRow >= 0)
    {
        Conversation * conversation = _conversations[currentSelectedRow];
        if (conversation.unread)
            [conversation markRead];
        else
            [conversation markUnread];
    }
}

-(void)showEmptyMessage
{
    [messageText clearHTML];
    [messageText setOverlayView:emptyMessageView];
}

/* Refresh the message list, preserving the selection.
 */
-(void)refreshList
{
    Conversation * selectedMessage = [self selectedMessage];
    [messageTable reloadData];
    [self restoreSelection:selectedMessage];
}

/* Return the current selected message
 */
-(Conversation *)selectedMessage
{
    NSInteger selectedRow = [messageTable selectedRow];
    return (selectedRow >= 0 && selectedRow < _conversations.count) ? _conversations[selectedRow] : nil;
}

/* Restore the selection to the specified message
 */
-(void)restoreSelection:(Conversation *)message
{
    if (message != nil && _conversations.count > 0)
    {
        NSInteger row = [_conversations indexOfObject:message];
        if (row != NSNotFound)
        {
            [messageTable setSelectedRow:row];
            return;
        }
    }
    [self showEmptyMessage];
}

/* Updates the article pane when the active display style has been changed.
 */
-(void)handleStyleChange:(NSNotificationCenter *)nc
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

-(void)showSelectedMessage
{
    NSInteger currentSelectedRow = [messageTable selectedRow];
    if (currentSelectedRow == -1)
        [self showEmptyMessage];
    else
    {
        [messageText clearOverlayView];
        
        Conversation * conversation = _conversations[currentSelectedRow];
        [messageText setHTML:[_currentStyleController styledTextForCollection:[conversation.messages allMessages]]];
    }
}

/* Return the Sort menu for this view from the XIB.
 */
-(NSMenu *)sortMenu
{
    return sortMenu;
}

/* Invoked when the user enters something in the search filter.
 */
-(void)filterViewByString:(NSString *)searchString
{
    Conversation * selectedMessage = [self selectedMessage];
    _conversations = [NSMutableArray arrayWithArray:[_currentFolder items]];
    if (![searchString isBlank])
    {
        NSPredicate * bPredicate =[NSPredicate predicateWithFormat:@"(SELF.subject contains[cd] %@) OR (SELF.author contains[cd] %@)", searchString, searchString];
        [_conversations filterUsingPredicate:bPredicate];
    }
    
    _currentStyleController.highlightString = searchString;

    [self sortConversations:YES];
    [self restoreSelection:selectedMessage];
}

/* Sort the conversations using the specified ordering.
 */
-(void)sortConversations:(BOOL)update
{
    NSString * keyName;
    SEL sel = NULL;
    switch (_currentSortOrder)
    {
        case Sort_Date:
            keyName = @"date";
            sel = @selector(compare:);
            break;

        case Sort_Author:
            keyName = @"author";
            sel = @selector(localizedCompare:);
            break;
            
        case Sort_Subject:
            keyName = @"subject";
            sel = @selector(localizedCompare:);
            break;
            
        default:
            NSAssert(NO, @"Unrecognised sort order!");
            return;
    }

    NSArray * recentArray = @[ [NSSortDescriptor sortDescriptorWithKey:keyName ascending:_sortAscending selector:sel] ];
    [_conversations sortUsingDescriptors:recentArray];
    [messageTable reloadData];

    [super sortConversations:update];
}

/* Return the count in the current list of messages in the table.
 */
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [_conversations count];
}

/* Handle the selection changing in the table view.
 */
-(void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    [self showSelectedMessage];
    
    bool isUnread = [self selectedMessage].unread;
    [(AppDelegate *)[NSApp delegate] addBacktrack:self.address withUnread:isUnread];
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
    Conversation * conversation = _conversations[row];
    MailCellView * result = [tableView makeViewWithIdentifier:@"summaryCell" owner:nil];
    if (result != nil)
    {
        NSString * subject = [conversation.subject unquoteAttributes];
        
        if ([subject isBlank])
            subject = NSLocalizedString(@"(No subject)", nil);

        Mugshot * mugshot = [Mugshot mugshotForUser:conversation.author];
        
        result.mugshot.image = mugshot.image;
        result.author.stringValue = conversation.author;
        result.date.stringValue = [[conversation.date GMTBSTtoUTC] friendlyDescription];
        result.subject.stringValue = subject;
        
        NSImageView * nextImage = result.image1;
        result.image1.image = nil;
        result.image2.image = nil;
        
        if (conversation.lastError)
        {
            nextImage.image = errorImage;
            nextImage = result.image2;
        }
        else if (conversation.unread)
        {
            nextImage.image = unreadImage;
            nextImage = result.image2;
        }
        
        if (conversation.messages.count > 1)
        {
            nextImage.image = nil;
            nextImage.image = replyImage;
        }
    }
    return result;
}
@end
