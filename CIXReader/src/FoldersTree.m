//
//  FoldersTree.m
//  CIXReader
//
//  Created by Steve Palmer on 20/08/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "FoldersTree.h"
#import "AppDelegate.h"
#import "CRTextCountCell.h"
#import "Preferences.h"
#import "TopicFolder.h"
#import "CategoryFolder.h"
#import "MailFolder.h"
#import "MessageEditor.h"
#import "StringExtensions.h"

@implementation FoldersTree

/* Do the things that only make sense once the NIB is loaded.
 */
-(void)awakeFromNib
{
    if (!_didInitialise)
    {
        Preferences * prefs = [Preferences standardPreferences];
        _showAllTopics = [prefs showAllTopics];

        [self setFolderListFont];
        
        _fireSelectionChangedEvent = YES;
        
        // Other settings
        [folderView sizeLastColumnToFit];
        [folderView setAutoresizesOutlineColumn:NO];
        [folderView setFloatsGroupRows:NO];
        [folderView setTarget:self];
        [folderView setEnableTooltips:YES];
        [folderView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];
        [folderView setMenu:[(AppDelegate *)[NSApp delegate] folderMenu]];
        
        // Register for dragging
        [folderView registerForDraggedTypes:@[ CR_PBoardType_FolderList, CR_PBoardType_MessageList ]];
        _didInitialise = YES;
    }
}

/* Do the things to initialize the folder tree from the database.
 * This must be called from the app delegate once the CIX object has
 * been instantiated.
 */
-(void)initialiseFoldersTree
{
    [self loadTree];
    
    // If the category list is empty, refresh it now
    NSInteger categoryCount = [[CIX.directoryCollection categories] count];
    if (categoryCount == 0)
        [CIX.directoryCollection refresh];
    
    // Register for notifications
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(handleFolderFontChange:) name:MA_Notify_FolderFontChange object:nil];
    [nc addObserver:self selector:@selector(handleShowAllTopicsChange:) name:MA_Notify_ShowAllTopicsChange object:nil];
    [nc addObserver:self selector:@selector(handleDirectoryChanged:) name:MADirectoryChanged object:nil];
    [nc addObserver:self selector:@selector(handleFolderAdded:) name:MAFolderAdded object:nil];
    [nc addObserver:self selector:@selector(handleFolderUpdated:) name:MAFolderUpdated object:nil];
    [nc addObserver:self selector:@selector(handleFolderDeleted:) name:MAFolderDeleted object:nil];
    [nc addObserver:self selector:@selector(handleFolderChanged:) name:MAFolderChanged object:nil];
    [nc addObserver:self selector:@selector(handleFolderRefreshed:) name:MAFolderRefreshed object:nil];
    [nc addObserver:self selector:@selector(handleConversationChanged:) name:MAConversationChanged object:nil];
    [nc addObserver:self selector:@selector(handleForumJoined:) name:MAForumJoined object:nil];
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0];
    [folderView expandItem:nil expandChildren:NO];
    [NSAnimationContext endGrouping];
}

/* Update the folders tree.
 */
-(void)update
{
    [folderView reloadData];
}

/* Handle changes to the directory by updating the category
 * list.
 */
-(void)handleDirectoryChanged:(NSNotification *)notification
{
    if (notification.object == nil)
    {
        [[_directoryTree mutableChildNodes] removeAllObjects];
        [self loadDirectoryTree:_directoryTree];
        [folderView reloadData];
    }
}

/* Handle a folder being deleted. Rebuild the forums
 * tree which will excluded the deleted folder.
 */
-(void)handleFolderDeleted:(NSNotification *)notification
{
    Folder * folder = notification.object;
    NSTreeNode * folderBase = [self folderWithID:folder.ID inNode:_forumsTree];

    if (folderBase != nil)
    {
        NSInteger selectedRow = [folderView selectedRow];
        NSInteger itemRow = [folderView rowForItem:folderBase];
        
        BOOL deletingCurrent = itemRow == selectedRow;
        
        NSTreeNode * parentNode = folderBase.parentNode;
        [[parentNode mutableChildNodes] removeObject:folderBase];
        
        [folderView reloadItem:parentNode reloadChildren:YES];
        
        if (deletingCurrent)
        {
            if (selectedRow == [folderView numberOfRows])
                --selectedRow;
        }
        [folderView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
    }
}

/* User has joined a new forum. Find it in the tree and select it.
 */
-(void)handleForumJoined:(NSNotification *)notification
{
    Response * resp = (Response *)notification.object;
    if (resp.errorCode == CCResponse_NoError)
    {
        Folder * newForum = resp.object;
        
        [self loadForumsTree:_forumsTree];
        id selectedItem = [self folderWithID:newForum.ID inNode:_forumsTree];
        [self setSelection:selectedItem withAddress:nil];
    }
}

/* Handle additions to the folder list by rebuilding the forums tree.
 */
-(void)handleFolderAdded:(NSNotification *)notification
{
    id selectedItem = [self selection];
    [self loadForumsTree:_forumsTree];
    [self setSelection:selectedItem withAddress:nil];
}

/* Respond to a change in the folder properties.
 */
-(void)handleFolderChanged:(NSNotification *)notification
{
    Folder * folder = notification.object;
    if (folder != nil)
        [self refreshSingleFolder:folder.ID];
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
        [self refreshSingleFolder:folder.ID];
    }
}

/* Refresh a single folder in the tree.
 */
-(void)refreshSingleFolder:(ID_type)ID
{
    NSTreeNode * folderBase = [self folderWithID:ID inNode:_forumsTree];
    if (folderBase != nil)
    {
        NSInteger row = [folderView rowForItem:folderBase];
        while (folderBase.parentNode != nil && row == -1)
        {
            folderBase = folderBase.parentNode;
            row = [folderView rowForItem:folderBase];
        }
        if (row != -1)
            [folderView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
    }
}

/* Handle updates to the forums tree by refreshing it
 */
-(void)handleFolderUpdated:(NSNotification *)notification
{
    id selectedItem = [self selection];
    [folderView reloadData];
    [self restoreSelection:selectedItem];
}

/* Called when the user changes the folder font and/or size in the Preferences
 */
-(void)handleFolderFontChange:(NSNotification *)notification
{
	[self setFolderListFont];
	[folderView reloadData];
}

/* Reload the folder tree if all topics view changes.
 */
-(void)handleShowAllTopicsChange:(NSNotification *)notification
{
    Preferences * prefs = [Preferences standardPreferences];
    _showAllTopics = [prefs showAllTopics];

    [self loadForumsTree:_forumsTree];
}

/* Respond to change in the count of unread messages on a conversation
 */
-(void)handleConversationChanged:(NSNotification *)notification
{
    [folderView reloadItem:_messagesTree reloadChildren:YES];
}

/* Given an address of a node, find and select that node. This will
 * cause the view for the node to be loaded and set to the given
 * address. Returns NO if the address cannot be located.
 */
-(BOOL)selectAddress:(Address *)address
{
    FolderBase * selection = [self folderFromAddress:address.schemeAndQuery];
    if (selection == nil)
        return NO;
    [self setSelection:selection withAddress:address];
    return YES;
}

/* Returns the FolderBase the selected item, or nil if no selection.
 */
-(FolderBase *)selection
{
    NSInteger row = [folderView selectedRow];
    return row >= 0 ? [folderView itemAtRow:row] : nil;
}

/* Restores the selection specified by the obj parameter without
 * firing a selection change event.
 */
-(void)restoreSelection:(FolderBase *)obj
{
    _fireSelectionChangedEvent = NO;
    [self setSelection:obj withAddress:nil];
    _fireSelectionChangedEvent = YES;
}

-(void)moveSelection:(FolderBase *)obj
{
    NSInteger row = [folderView rowForItem:obj];

    if (row >= 0)
    {
        _fireSelectionChangedEvent = NO;
        [folderView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
        [folderView scrollRowToVisible:row];
        _fireSelectionChangedEvent = YES;
    }
}

/* Restore a selection obtained from saveSelection
 */
-(void)setSelection:(FolderBase *)obj withAddress:(Address *)address
{
    if (obj != nil)
    {
        NSInteger row = [folderView rowForItem:obj];
        if (row == -1 && obj.parentNode != nil)
        {
            // Not found? Maybe it is inside a collapsed parent so expand the
            // parent and then try again.
            if (![folderView isItemExpanded:obj.parentNode])
            {
                [folderView expandItem:obj.parentNode expandChildren:YES];
                row = [folderView rowForItem:obj];
            }
        }
        if (row == [folderView selectedRow])
        {
            [(AppDelegate *)[NSApp delegate] selectViewForFolder:obj withAddress:address options:0];
            return;
        }
        if (row >= 0)
        {
            _lastAddress = address;
            [folderView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
        }
    }
}

/* Creates or updates the fonts used by the folder list. The folder
 * list isn't automatically refreshed afterward - call reloadData for that.
 */
-(void)setFolderListFont
{
	int height;
    
	Preferences * prefs = [Preferences standardPreferences];
	_cellFont = [NSFont fontWithName:[prefs folderListFont] size:[prefs folderListFontSize]];
    
	height = [[(AppDelegate *)[NSApp delegate] layoutManager] defaultLineHeightForFont:_cellFont];
	[folderView setRowHeight:height + 5];
	[folderView setIntercellSpacing:NSMakeSize(10, 2)];
}

/* Called when the popup menu is opened on the folder list. We move the
 * selection to whichever node is under the cursor so the context between
 * the menu items and the node is made clear.
 */
-(void)outlineView:(CRFolderView *)olv menuWillAppear:(NSEvent *)theEvent
{
    NSInteger row = [olv rowAtPoint:[olv convertPoint:[theEvent locationInWindow] fromView:nil]];
    if (row >= 0)
    {
        // Select the row under the cursor if it isn't already selected
        if ([olv numberOfSelectedRows] <= 1)
            [olv selectRowIndexes:[NSIndexSet indexSetWithIndex:(NSUInteger )row] byExtendingSelection:NO];
    }
}

/* Load the folder tree
 */
-(void)loadTree
{
    _root = [[FolderBase alloc] initWithRepresentedObject:nil];
    
    // CIX Forums directory with a list of categories.
    _homePage = [[FolderBase alloc] init];
    [_homePage setName:NSLocalizedString(@"Home", nil)];
    [[_root mutableChildNodes] addObject:_homePage];
    
    // CIX Forums directory with a list of categories.
    _directoryTree = [[FolderBase alloc] init];
    [_directoryTree setName:NSLocalizedString(@"Directory", nil)];
    [[_root mutableChildNodes] addObject:_directoryTree];
    [self loadDirectoryTree:_directoryTree];

    // CIX PMessage inbox (no child nodes)
    _messagesTree = [[MailGroup alloc] init];
    [_messagesTree setName:NSLocalizedString(@"Messages", nil)];
    [[_root mutableChildNodes] addObject:_messagesTree];
    [self loadMessageTree:_messagesTree];

    // All subscribed forums and topics
    _forumsTree = [[ForumGroup alloc] init];
    [_forumsTree setName:NSLocalizedString(@"Forums", nil)];
    [[_root mutableChildNodes] addObject:_forumsTree];
    [self loadForumsTree:_forumsTree];

    [folderView expandItem:_messagesTree];
    [folderView expandItem:_forumsTree];
    
    [folderView reloadData];
}

/* Reload the folders tree from scratch, preserving any prior
 * selection.
 */
-(void)loadForumsTree:(NSTreeNode *)parent
{
    NSMutableArray * childNodes = [parent mutableChildNodes];
    [childNodes removeAllObjects];
    
    for (Folder * folder in CIX.folderCollection)
    {
        if (IsTopLevelFolder(folder))
        {
            TopicFolder * topicFolder = [[TopicFolder alloc] initWithFolder:folder];
            topicFolder.name = folder.name;
            [childNodes addObject:topicFolder];
            
            NSArray * childFolders = [folder children];
            for (Folder *childFolder in childFolders)
            {
                TopicFolder * childTopicFolder = [[TopicFolder alloc] initWithFolder:childFolder];
                BOOL showArchivedTopic = _showAllTopics || (!childFolder.isRecent && childFolder.unread > 0);
                if (showArchivedTopic || childFolder.isRecent)
                {
                    childTopicFolder.name = childFolder.name;
                    [[topicFolder mutableChildNodes] addObject:childTopicFolder];
                }
            }
        }
    }
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"folder.treeIndex" ascending:YES];
    [parent sortWithSortDescriptors:@[ sortDescriptor ] recursively:YES];

    SmartFolder * starredFolder = [[SmartFolder alloc] init];
    starredFolder.name = NSLocalizedString(@"Starred", nil);
    starredFolder.criteria = @"starred=1";
    starredFolder.containComparator = ^BOOL(Message * message) { return message.starred; };
    [childNodes insertObject:starredFolder atIndex:0];
    
    SmartFolder * draftsFolder = [[SmartFolder alloc] init];
    draftsFolder.name = NSLocalizedString(@"Drafts", nil);
    draftsFolder.criteria = [NSString stringWithFormat:@"RemoteID>=%d and PostPending=0", INT32_MAX/2];
    draftsFolder.containComparator = ^BOOL(Message * message) { return message.isDraft; };
    [childNodes insertObject:draftsFolder atIndex:1];
    
    SmartFolder * outboxFolder = [[SmartFolder alloc] init];
    outboxFolder.name = NSLocalizedString(@"Outbox", nil);
    outboxFolder.criteria = @"PostPending=1";
    outboxFolder.containComparator = ^BOOL(Message * message) { return message.postPending; };
    [childNodes insertObject:outboxFolder atIndex:2];
    
    if (_searchFolder != nil)
        [childNodes insertObject:_searchFolder atIndex:0];
    
    [folderView reloadData];
}

/* Reload the parent's children.
 */
-(void)reloadForumTreeFromNode:(TopicFolder *)parent
{
    [parent.mutableChildNodes removeAllObjects];
    NSArray * childFolders = [parent.folder children];
    for (Folder *childFolder in childFolders)
    {
        TopicFolder * childTopicFolder = [[TopicFolder alloc] initWithFolder:childFolder];
        BOOL showArchivedTopic = _showAllTopics || (!childFolder.isRecent && childFolder.unread > 0);
        if (showArchivedTopic || childFolder.isRecent)
        {
            childTopicFolder.name = childFolder.name;
            [[parent mutableChildNodes] addObject:childTopicFolder];
        }
    }

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"folder.treeIndex" ascending:YES];
    [parent sortWithSortDescriptors:@[ sortDescriptor ] recursively:YES];

    [folderView reloadData];
}

/* Load the top-level folders for the pmessage system.
 */
-(void)loadMessageTree:(NSTreeNode *)parent
{
    MailFolder * inboxFolder = [[MailFolder alloc] initWithName:NSLocalizedString(@"Inbox", nil) andImage:[NSImage imageNamed:@"inbox.tiff"]];
    [[parent mutableChildNodes] addObject:inboxFolder];
}

/* Load the list of categories that make up the directory
 */
-(void)loadDirectoryTree:(NSTreeNode *)parent
{
    NSMutableArray * childNodes = [parent mutableChildNodes];
    for (NSString * categoryName in [CIX.directoryCollection.categories sortedArrayUsingSelector:@selector(localizedCompare:)])
    {
        CategoryFolder * categoryFolder = [[CategoryFolder alloc] initWithName:categoryName];
        [childNodes addObject:categoryFolder];
    }
    
    CategoryFolder * categoryFolder = [[CategoryFolder alloc] initWithName:[CategoryFolder allCategoriesName]];
    [childNodes insertObject:categoryFolder atIndex:0];
}

/* Respond to a click on the count button to mark all messages in the folder as read.
 */
-(IBAction)handleMarkRead:(id)sender
{
    CRButton * button = (CRButton *)sender;
    FolderBase * folder = button.representedObject;
    [folder markAllRead];
}

-(SearchFolder *)searchFolder
{
    if (_searchFolder == nil)
    {
        _searchFolder = [SearchFolder new];
        _searchFolder.containComparator = ^BOOL(Message * message) { return YES; };

        NSMutableArray * childNodes = [_forumsTree mutableChildNodes];
        [childNodes insertObject:_searchFolder atIndex:0];
        [folderView reloadItem:_forumsTree reloadChildren:YES];
    }
    return _searchFolder;
}

-(void)selectSearchFolder
{
    [self setSelection:_searchFolder withAddress:nil];
}

/* Navigate to the next folder that contains unread messages and invoke the view
 * to display it.
 */
-(void)nextUnread:(FolderOptions)options
{
    NSInteger row = [folderView selectedRow];
    BOOL resetLoop = NO;
    if (row == -1)
        row = 0;
    
    FolderBase * startingFolder = [folderView itemAtRow:row];
    FolderBase * folder = startingFolder;
    
    BOOL acceptSmartFolders = IsSmartFolder(startingFolder);
    BOOL priorityOnly = (options & FolderOptionsPriority) == FolderOptionsPriority;
    
    do {
        if (folder.viewForFolder == AppViewForum)
        {
            TopicFolder * topic = (TopicFolder *)folder;
            if (priorityOnly ? topic.unreadPriority : topic.unread)
            {
                if (startingFolder.viewForFolder == AppViewTopic)
                {
                    // Collapse the last node we were on if it was expanded
                    FolderBase * parentNode = (FolderBase *)[startingFolder parentNode];
                    if (parentNode.parentNode != _root)
                        [folderView collapseItem:parentNode];
                }
                [folderView expandItem:topic expandChildren:YES];
                row = [folderView rowForItem:topic];
            }
        }
        else if (folder.class == ForumGroup.class)
        {
            ForumGroup * group = (ForumGroup *)folder;
            if (group.unread > 0)
                [folderView expandItem:folder expandChildren:NO];
        }
        else if (folder.class == MailGroup.class)
        {
            MailGroup * group = (MailGroup *)folder;
            if (group.unread > 0)
                [folderView expandItem:folder expandChildren:NO];
        }
        else
        {
            if ((acceptSmartFolders && [folder isKindOfClass:SmartFolder.class]) || (priorityOnly ? folder.unreadPriority : folder.unread))
            {
                if ([(AppDelegate *)[NSApp delegate] selectViewForFolder:folder withAddress:nil options:options])
                {
                    [self moveSelection:folder];
                    return;
                }
            }
        }
        if (++row == [folderView numberOfRows])
        {
            if (resetLoop)
                break;
            row = 0;
            resetLoop = YES;
        }
        options |= FolderOptionsReset;
        folder = [folderView itemAtRow:row];
        acceptSmartFolders = NO;
    } while (folder != startingFolder);
}

/* Return the folder whose address corresponds to the given address.
 */
-(FolderBase *)folderFromAddress:(NSString *)address
{
    return [self folderFromAddress:address inNode:_root];
}

/* Recursively locate the folder whose address corresponds to the given address
 * by starting at the specified FolderBase node and searching all children
 * inclusively. Returns nil if no folder is found that corresponds to the address.
 */
-(FolderBase *)folderFromAddress:(NSString *)address inNode:(NSTreeNode *)node
{
    if (node != nil)
    {
        FolderBase * folder = (FolderBase *)node;
        if (folder.address != nil && [folder.address isEqualToString:address])
            return folder;
        
        NSArray * nodes = [node childNodes];
        for (NSTreeNode * child in nodes)
        {
            FolderBase * childNode = [self folderFromAddress:address inNode:child];
            if (childNode != nil)
                return childNode;
        }
        
        // Not found, but possibly topic may be non-recent and hidden, so
        // look for it and unhide it.
        Address * addr = [[Address alloc] initWithString:address];
        if ([addr.scheme isEqualToString:@"cix"] && addr.query != nil)
        {
            NSArray * splitAddress = [addr.query componentsSeparatedByString:@"/"];
            if (splitAddress.count == 2)
            {
                Folder * forum = [CIX.folderCollection folderByName:splitAddress[0]];
                Folder * topic = [forum childByName:splitAddress[1]];
                
                if (forum != nil && topic != nil && !topic.isRecent)
                {
                    topic.flags |= FolderFlagsRecent;
                    [topic save];
                 
                    FolderBase * forumFolder = [self folderWithID:forum.ID inNode:_root];
                    [self reloadForumTreeFromNode:(TopicFolder *)forumFolder];
                    
                    return [self folderWithID:topic.ID inNode:forumFolder];
                }
            }
        }
    }
    return nil;
}

/* Return the folder in the forums tree whose ID matches the specified
 * folder ID, or nil if not found. Since this does not search closed nodes,
 * it will return nil for a folder whose parent is collapsed.
 */
-(FolderBase *)folderWithID:(ID_type)folderID inNode:(NSTreeNode *)node
{
    NSArray * nodes = [node childNodes];
    for (FolderBase * child in nodes)
    {
        if ([child isKindOfClass:TopicFolder.class])
        {
            TopicFolder * topic = (TopicFolder *)child;
            if (topic.folder != nil && topic.folder.ID == folderID)
                return child;
        }
        FolderBase * subChild = [self folderWithID:folderID inNode:child];
        if (subChild != nil)
            return subChild;
    }
    return nil;
}

/* Handle selection change. Obtain the type of the folder selected and invoke
 * the appropriate view, passing through the folder to that view.
 */
-(void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    if (_fireSelectionChangedEvent)
    {
        FolderBase * node = [folderView itemAtRow:[folderView selectedRow]];
        if (node != nil)
        {
            [(AppDelegate *)[NSApp delegate] selectViewForFolder:node withAddress:_lastAddress options:0];
            _lastAddress = nil;
        }
    }
}

-(BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(id)item
{
    return !_isInDrag;
}

/* Tell the outline view if the specified item can be expanded. The answer is
 * yes if we have children, no otherwise.
 */
-(BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    NSTreeNode * node = (item != nil) ? (NSTreeNode *)item : _root;
	return node.childNodes.count > 0;
}

/* Don't allow selection on group items.
 */
-(BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	NSTreeNode * node = (NSTreeNode *)item;
    return node == _homePage || node.parentNode != _root;
}

/* Returns the number of children belonging to the specified item
 */
-(NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    NSTreeNode * node = (item != nil) ? (NSTreeNode *)item : _root;
	return node.childNodes.count;
}

/* Returns the child at the specified offset of the item
 */
-(id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
    NSTreeNode * node = (item != nil) ? (NSTreeNode *)item : _root;
	return node.childNodes[index];
}

/* For items that have counts, we show a tooltip that aggregates the counts.
 */
-(NSString *)outlineView:(CRFolderView *)outlineView tooltipForItem:(id)item
{
    if (item == _forumsTree)
    {
        NSInteger unread = CIX.folderCollection.totalUnread;
        if (unread > 0)
            return [NSString stringWithFormat:@"%li unread messages", unread];
    }
    if ([item isKindOfClass:TopicFolder.class])
    {
        TopicFolder * folder = (TopicFolder *)item;
        if (folder.unread > 0)
            return [NSString stringWithFormat:@"%li unread messages", (long)folder.unread];
    }
	return nil;
}

/* Return whether the specified item is a top-level group item.
 */
-(BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
	NSTreeNode * node = (NSTreeNode *)item;
    return node.parentNode == _root;
}

/* Allow show/hide on top level items.
 */
-(BOOL)outlineView:(NSOutlineView *)outlineView shouldShowOutlineCellForItem:(id)item
{
    NSTreeNode * node = (item != nil) ? (NSTreeNode *)item : _root;
    return node.childNodes.count > 0;
}

/* Redraw the node being expanded because we may need to hide the count icon
 */
-(void)outlineViewItemDidExpand:(NSNotification *)notification
{
    id item = notification.userInfo;
    if (item != nil)
    {
        FolderBase * node = [item objectForKey: @"NSObject"];
        NSInteger nodeIndex = [folderView rowForItem:node];
        [folderView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:nodeIndex] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
    }
}

/* Redraw the node being collapsed because we may need to show the count icon
 */
-(void)outlineViewItemDidCollapse:(NSNotification *)notification
{
    id item = notification.userInfo;
    if (item != nil)
    {
        FolderBase * node = [item objectForKey: @"NSObject"];
        NSInteger nodeIndex = [folderView rowForItem:node];
        [folderView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:nodeIndex] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
    }
}

/* Return the view that draws the specified folder list item.
 */
-(NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	FolderBase * node = (FolderBase *)item;

    // For the groups, we just return a regular text view.
    if (node.parentNode == _root)
    {
        NSTextField *result = [outlineView makeViewWithIdentifier:@"HeaderTextField" owner:self];
        NSString *value = [node.name uppercaseString];
        [result setStringValue:value];
        return result;
    }
    
    // For everything else, we draw the string and associated image, plus
    // a button if required.
    CRTextCountCell *result = [outlineView makeViewWithIdentifier:@"MainCell" owner:self];
    result.textField.stringValue = SafeString(node.name);
    result.textField.font = _cellFont;
    result.textField.textColor = (node.flags & FolderFlagsResigned) ? [NSColor darkGrayColor] : [NSColor textColor];
    result.imageView.image = node.icon;

    // Show unread count only for items that are collapsed or are leaf
    // nodes in the tree.
    if (node.childNodes.count > 0 && [outlineView isItemExpanded:item])
        [result.button setHidden:YES];
    else
    {
        NSInteger unreadCount = node.unread;
        if (unreadCount == 0)
            [result.button setHidden:YES];
        else
        {
            [result.button setHidden:NO];
            [result.button setRepresentedObject:item];
            [result.button setTitle:[NSString stringWithFormat:@"%li", unreadCount]];
        }
    }
    return result;
}

/* Prepare for dragging, both within CIXReader and outside. For internal drags, we write the indexes
 * of the selected item to the pasteboard. For external drags, we write the addresses of the selected
 * item to the pasteboard. Note this code handles multiple selections.
 */
-(BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pasteboard
{
    NSUInteger count = items.count;

    NSMutableString * stringDragData = [NSMutableString string];
    NSMutableArray * internalDragData = [NSMutableArray arrayWithCapacity:count];

    [pasteboard declareTypes:@[ CR_PBoardType_FolderList, NSStringPboardType ] owner:self];

    int countOfItems = 0;
    for (int index = 0; index < count; ++index)
    {
        FolderBase * node = items[index];
        if ([node isKindOfClass:[TopicFolder class]])
        {
            [stringDragData appendString:node.address];
            [stringDragData appendString:@"\n"];
            ++countOfItems;
            
            NSInteger sourceIndex = [outlineView rowForItem:node];
            [internalDragData addObject:[NSNumber numberWithLong:sourceIndex]];
        }
    }
    [pasteboard setString:stringDragData forType:NSStringPboardType];
    [pasteboard setPropertyList:internalDragData forType:CR_PBoardType_FolderList];
    
    _isInDrag = YES;
    return countOfItems > 0;
}

/* Called when something is being dragged over us. We respond with an NSDragOperation value indicating the
 * feedback for the user given where we are.
 */
-(NSDragOperation)outlineView:(NSOutlineView*)olv validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)index
{
    NSPasteboard * pb = [info draggingPasteboard];
    NSString * type = [pb availableTypeFromArray:@[ CR_PBoardType_FolderList, CR_PBoardType_MessageList ]];
    
    if ([type isEqualToString:CR_PBoardType_FolderList])
    {
        FolderBase * node = (FolderBase *)item;
        if ([node isKindOfClass:[TopicFolder class]])
        {
            NSArray * arrayOfSources = [pb propertyListForType:type];
            if (arrayOfSources != nil && arrayOfSources.count > 0)
            {
                NSInteger sourceIndex = [arrayOfSources[0] longValue];
                FolderBase * sourceNode = [olv itemAtRow:sourceIndex];
                
                // Don't allow dropping ON a node
                if (index == -1)
                    return NSDragOperationNone;
                
                // IF the node we're dropping over has the same parent node, OR
                // the node's parent is the same as the sourceNode then we're good.
                if (sourceNode.parentNode == node)
                    return NSDragOperationMove;
                
                if (sourceNode.parentNode == _forumsTree && node.parentNode == _forumsTree)
                    return NSDragOperationMove;
            }
        }
    }

    // Dropping a message list. Only permit if we can post messages to the folder.
    if ([type isEqualToString:CR_PBoardType_MessageList])
    {
        FolderBase * node = (FolderBase *)item;
        if ([node isKindOfClass:[TopicFolder class]])
        {
            TopicFolder * topicFolder = (TopicFolder *)node;
            if (!IsTopLevelFolder(topicFolder.folder))
            {
                Folder * forumFolder = topicFolder.folder.parentFolder;
                DirForum * forum = [CIX.directoryCollection forumByName:forumFolder.name];
                if (forum.isModerator || !IsReadOnly(topicFolder.folder))
                    return NSDragOperationCopy;
            }
        }
    }
    
    // For any other folder, can't drop anything ON them.
    return NSDragOperationNone;
}

/* Because we get a crash if we attempt to reload the forums tree in acceptDrop, we hook into
 * the dragCompleted notification from the CRFolderView and test whether we need to reload
 * and do it here.
 */
-(void)outlineView:(CRFolderView *)olv dragCompleted:(BOOL)deposited
{
    if (_needReload && deposited)
    {
        [self loadForumsTree:_forumsTree];
        _needReload = NO;
    }
    _isInDrag = NO;
}

/* Accept a drop on or between nodes either from within the folder view or from outside. By the time
 * we get here, the target would have been validated by validateDrop so we just set the treeIndex of the
 * source to the child index and call FolderCollection.reindex to rebuild the tree indexes.
 */
-(BOOL)outlineView:(NSOutlineView *)olv acceptDrop:(id <NSDraggingInfo>)info item:(id)targetItem childIndex:(int)child
{
    NSPasteboard * pb = [info draggingPasteboard];
    NSString * type = [pb availableTypeFromArray:@[ CR_PBoardType_FolderList, CR_PBoardType_MessageList ]];
    
    _isInDrag = NO;
    if ([type isEqualToString:CR_PBoardType_FolderList])
    {
        if ([targetItem isKindOfClass:[TopicFolder class]])
        {
            TopicFolder * node = (TopicFolder *)targetItem;
            NSArray * arrayOfSources = [pb propertyListForType:type];
            if (arrayOfSources != nil && arrayOfSources.count > 0)
            {
                NSInteger sourceIndex = [arrayOfSources[0] longValue];
                TopicFolder * sourceNode = [olv itemAtRow:sourceIndex];
                
                if (sourceNode.parentNode == _forumsTree && node.parentNode == _forumsTree)
                {
                    Folder * folder = sourceNode.folder;
                    Folder * nextFolder = node.folder;

                    [folder.parentFolder move:folder toAfter:nextFolder];
                    _needReload = YES;
                    return YES;
                }
                
                if (sourceNode.parentNode == node)
                {
                    Folder * folder = sourceNode.folder;
                    TopicFolder * nextFolder = nil;
                    
                    if (child == -1)
                        child = 0; // Dropped on the parent
                    
                    if (child >= 0 && child < node.childNodes.count)
                        nextFolder = (TopicFolder *)node.childNodes[child];
                    
                    [folder.parentFolder move:folder toBefore:nextFolder.folder];
                    [self reloadForumTreeFromNode:(TopicFolder *)sourceNode.parentNode];
                    return YES;
                }
            }
        }
    }
    if ([type isEqualToString:CR_PBoardType_MessageList])
    {
        if ([targetItem isKindOfClass:[TopicFolder class]])
        {
            TopicFolder * node = (TopicFolder *)targetItem;
            NSArray * arrayOfMessages = [pb propertyListForType:type];
            
            NSDateFormatter * dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateFormat:@"ddMMMyyyy HH:MM"];
            
            for (NSDictionary * source in arrayOfMessages)
            {
                Message * newMessage = [Message new];
                NSMutableString * newtext = [[NSMutableString alloc] init];
                
                int sourceTopicID = [source[@"TopicID"] intValue];
                int sourceMessageID = [source[@"MessageID"] intValue];

                Folder * topic = [CIX.folderCollection folderByID:sourceTopicID];
                Folder * forum = [topic parentFolder];
                Message * sourceMessage = [[topic messages] messageByID:sourceMessageID];
                
                [newtext appendFormat:@"***COPIED FROM: >>>%@/%@ %d ", forum.name, topic.name, sourceMessage.remoteID];
                [newtext appendFormat:@"%@(%ld)", sourceMessage.author, sourceMessage.body.length];
                [newtext appendFormat:@"%@ ", [dateFormat stringFromDate:sourceMessage.date]];
                
                if (sourceMessage.commentID > 0)
                    [newtext appendFormat:@"c%d ", sourceMessage.commentID];
                
                [newtext appendString:@"\n"];
                [newtext appendString:sourceMessage.body];
                [newtext appendString:@"\n"];

                newMessage.topicID = node.ID;
                newMessage.body = newtext;
                
                MessageEditor * msgWindow = [[MessageEditor alloc] initWithMessage:newMessage addSignature:NO];
                [msgWindow showWindow:self];
                [[msgWindow window] makeKeyAndOrderFront:self];
            }
        }
    }
    return NO;
}
@end
