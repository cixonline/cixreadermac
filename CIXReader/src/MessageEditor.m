//
//  MessageEditor.m
//  CIXReader
//
//  Created by Steve Palmer on 04/11/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "MessageEditor.h"
#import "Constants.h"
#import "Preferences.h"
#import "StringExtensions.h"
#import "ImageExtensions.h"
#import "DateExtensions.h"
#import "CRToolbarItem.h"
#import "WindowCollection.h"

// Private interfaces
@interface MessageEditor (Private)
-(void)handleMessageFontChange:(NSNotification *)notification;
-(void)handleSignaturesChange:(NSNotification *)notification;
-(void)setMessageFont;
-(void)updateTitle;
-(void)insertSignature:(NSString *)signatureTitle;
-(void)reloadSignaturesList;
@end

@implementation MessageEditor

/* Create a new message with the specified message parent
 */
-(id)initWithMessage:(Message *)message addSignature:(BOOL)addSignature
{
    if ((self = [self init]) != nil)
    {
        _originalMessage = message;
        _addSignature = addSignature;
        _folder = [CIX.folderCollection folderByID:message.topicID];
    }
    return self;
}

/* Create a new message with the specified message parent
 */
-(id)initWithFolder:(Folder *)folder
{
    if ((self = [self init]) != nil)
    {
        _originalMessage = nil;
        _addSignature = YES;
        _folder = folder;
    }
    return self;
}

/* Create a new message window.
 */
-(id)init
{
    return [super initWithWindowNibName:@"MessageEditor"];
}

/* windowDidLoad
 */
-(void)windowDidLoad
{
    // Create the toolbar.
    NSToolbar * toolbar = [[NSToolbar alloc] initWithIdentifier:@"MA_MessageEditorToolbar"];
    
    // Set the appropriate toolbar options. We are the delegate, customization is allowed,
    // changes made by the user are automatically saved and we start in icon+text mode.
    [toolbar setDelegate:self];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
    [messageWindow setToolbar:toolbar];

    [messageWindow setDelegate:self];
    [messageWindow setBackgroundColor:[NSColor controlBackgroundColor]];

    [textView setAutomaticQuoteSubstitutionEnabled:NO];
    [textView setAutomaticDashSubstitutionEnabled:NO];
    
    // Add this to the window collection to ensure that a reference is
    // maintained.
    [[WindowCollection defaultCollection] add:self];
    
    // Make sure we're notified if the message font changes
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(handleMessageFontChange:) name:MA_Notify_MessageFontChange object:nil];
    
    // Also wants to be notified if the list of signatures changes
    [nc addObserver:self selector:@selector(handleSignaturesChange:) name:MA_Notify_SignaturesChange object:nil];
    
    // Text change notifications
    [nc addObserver:self selector:@selector(textDidChange:) name: NSTextDidChangeNotification object:textView];
    
    // Init the list of signatures
    _currentSignature = nil;
    [self reloadSignaturesList];
    
    // Set the current message
    if (_originalMessage != nil)
        [[textView textStorage] setAttributedString:_originalMessage.attributedBody];

    // Set the message font
    Preferences * prefs = [Preferences standardPreferences];
    NSFont * font = [NSFont fontWithName:[prefs messageFont] size:[prefs messageFontSize]];
    [self setMessageFont:font];

    // If the text is empty, insert the forum signature if there is one,
    // otherwise the default signature.
    NSString * defaultSignature = nil;
    if (_originalMessage != nil)
    {
        Folder * topic = [CIX.folderCollection folderByID:_originalMessage.topicID];
        Folder * forum = [topic parentFolder];
        if ([[Signatures defaultSignatures] signatureForTitle:forum.name] != nil)
            defaultSignature = forum.name;
    }
    if (defaultSignature == nil)
        defaultSignature = [prefs defaultSignature];
    if (_addSignature && ![defaultSignature isEqualToString:[Signatures noSignaturesString]])
    {
        // Select default signature for this folder(conference)
        NSString * signature = defaultSignature;
		[signaturesList selectItemWithTitle:signature];
        [self insertSignature:signature];
    }
    
    // Set the window title
    [self updateTitle];
}

/* handleMessageFontChange
 * Called when the user changes the message or plain text font and/or size in the Preferences
 */
-(void)handleMessageFontChange:(NSNotification *)notification
{
    NSFont * newFont = notification.object;
    [self setMessageFont:newFont];
}

/* handleSignaturesChange
 * Called when a signature is modified, added or removed from the global signature list.
 * This is a cue for us to refresh the signatures drop-down list.
 */
-(void)handleSignaturesChange:(NSNotification *)notification
{
    [self reloadSignaturesList];
}

/* reloadSignaturesList
 * Refresh the signatures drop down list.
 */
-(void)reloadSignaturesList
{
    NSArray * arrayOfSignatures = [[Signatures defaultSignatures] signatureTitles];
    NSUInteger index;
    
    [signaturesList removeAllItems];
    [signaturesList addItemWithTitle:[Signatures noSignaturesString]];
    for (index = 0; index < [arrayOfSignatures count]; ++index)
        [signaturesList addItemWithTitle:arrayOfSignatures[index]];
}

/* signatureSelected
 */
-(IBAction)signatureSelected:(id)sender
{
    [self insertSignature:[sender titleOfSelectedItem]];
}

/* This is the routine that actually inserts a signature into the text.
 */
-(void)insertSignature:(NSString *)signatureTitle
{
    NSMutableString * msgText = [NSMutableString stringWithString:[textView string]];
    NSRange textRange = NSMakeRange(0, [msgText length]);
    NSRange selRange = [textView selectedRange];
    NSString * newSignature = @"";
    BOOL doAppend = YES;
    
    if (![signatureTitle isEqualToString:[Signatures noSignaturesString]])
        newSignature = [NSString stringWithFormat:@"\n\n%@", [[Signatures defaultSignatures] expandSignatureForTitle:signatureTitle]];
    
    if (_currentSignature != nil)
    {
        NSRange range = [msgText rangeOfString:_currentSignature options:NSLiteralSearch range:textRange];
        if (range.location != NSNotFound)
        {
            [msgText replaceCharactersInRange:range withString:newSignature];
            [textView setString:msgText];
            doAppend = NO;
        }
    }
    if (doAppend)
    {
        NSAttributedString * attrText = [[NSAttributedString alloc] initWithString:newSignature attributes:[textView typingAttributes]];
        [[textView textStorage] insertAttributedString:attrText atIndex:[msgText length]];
    }
    
    _currentSignature = newSignature;
    [textView setSelectedRange:selRange];
}

/* Set the font used by the editor
 */
-(void)setMessageFont:(NSFont *)newFont
{
    [textView setFont:newFont];
}

/* When the window is about to close, remove ourselves from the
 * collection.
 */
-(void)windowWillClose:(NSNotification *)notification
{
    [[WindowCollection defaultCollection] remove:self];
}

/* Since we established ourselves as the delegate for the window, we will
 * get the notifications when the window closes.
 */
-(BOOL)windowShouldClose:(NSNotification *)notification
{
    [self.window orderFront:self];
    if ([messageWindow isDocumentEdited])
    {
        NSInteger returnCode = NSRunAlertPanel(NSLocalizedString(@"Message not saved", nil),
                                     NSLocalizedString(@"This message has not been saved. Are you sure you want to discard it?", nil),
                                     NSLocalizedString(@"Save", nil),
                                     NSLocalizedString(@"Cancel", nil),
                                     NSLocalizedString(@"Don't Save", nil));
        if (returnCode == NSAlertDefaultReturn)
        {
            [self save:self];
            [messageWindow setDocumentEdited:NO];
        }
        if (returnCode == NSAlertOtherReturn)
            [messageWindow setDocumentEdited:NO];
    }
    if (![messageWindow isDocumentEdited])
        return YES;
    
    return NO;
}

/* Insert the original message quoted at the cursor position.
 */
-(IBAction)quoteOriginal:(id)sender
{
    if (_originalMessage != nil && _originalMessage.commentID > 0)
    {
        Message * parentMessage = _originalMessage.parent;
        [textView insertText:parentMessage.quotedBody];
    }
}

/* Save the message to the database but do not send it
 * and do not close the window.
 */
-(IBAction)save:(id)sender
{
    if (_originalMessage == nil)
    {
        _originalMessage = [Message new];
        _originalMessage.topicID = _folder.ID;
    }
    _originalMessage.author = CIX.username;
    _originalMessage.date = [[NSDate date] UTCtoGMTBST];
    _originalMessage.postPending = NO;
    
    [self readAttributedText:_originalMessage];
    
    [_folder.messages add:_originalMessage];
    
    [messageWindow setDocumentEdited:NO];
}

/* Save the message to the database and send it if we're online.
 */
-(IBAction)sendMessage:(id)sender
{
    if (_originalMessage == nil)
    {
        _originalMessage = [Message new];
        _originalMessage.topicID = _folder.ID;
    }
    _originalMessage.author = CIX.username;
    _originalMessage.date = [[NSDate date] UTCtoGMTBST];
    _originalMessage.postPending = YES;
    
    [self readAttributedText:_originalMessage];

    [_folder.messages add:_originalMessage];
    
    [messageWindow setDocumentEdited:NO];
    [messageWindow performClose:self];
}

/* Insert an image at the cursor position.
 */
-(IBAction)handleInsertImage:(id)sender
{
    NSOpenPanel * openDlg = [NSOpenPanel openPanel];
    
    [openDlg setCanChooseFiles:YES];
    [openDlg setAllowedFileTypes:@[ @"jpg", @"gif", @"png" ]];
    [openDlg setAllowsMultipleSelection:YES];
    
    if ([openDlg runModal] == NSOKButton)
    {
        NSArray * files = [openDlg URLs];
        for (NSURL * file in files)
        {
            NSImage * pic = [[NSImage alloc] initWithContentsOfURL:file];
            NSTextAttachmentCell * attachmentCell = [[NSTextAttachmentCell alloc] initImageCell:pic];
            NSTextAttachment * attachment = [[NSTextAttachment alloc] init];
            [attachment setAttachmentCell: attachmentCell];
            NSAttributedString * attributedString = [NSAttributedString attributedStringWithAttachment: attachment];
            
            [[textView textStorage] insertAttributedString:attributedString atIndex:textView.selectedRange.location];
        }
    }
}

/* Read the text from the edit control and parse off any attachments and save those
 * separately. Attachments are replaced by placeholders of the form {n} where n is the
 * 1-based index of the attachment.
 */
-(void)readAttributedText:(Message *)message
{
    NSMutableAttributedString * attrTextString = [[NSMutableAttributedString alloc] initWithAttributedString:[textView attributedString]];
    NSRange theStringRange = NSMakeRange(0, [attrTextString length]);
    
    [message deleteAttachments];
    
    if (theStringRange.length > 0)
    {
        [[attrTextString mutableString] replaceString:@"{" withString:@"{{"];
        [[attrTextString mutableString] replaceString:@"}" withString:@"}}"];

        int attachmentIndex = 1;
        NSInteger index = 0;
        do
        {
            NSRange theEffectiveRange;
            NSDictionary * theAttributes = [attrTextString attributesAtIndex:index longestEffectiveRange:&theEffectiveRange inRange:theStringRange];
            NSTextAttachment * theAttachment = [theAttributes objectForKey:NSAttachmentAttributeName];
            if (theAttachment == nil)
                index = theEffectiveRange.location + theEffectiveRange.length;
            else
            {
                NSTextAttachmentCell * textAttachmentCell = (NSTextAttachmentCell *)theAttachment.attachmentCell;
                NSImage * attachmentImage = textAttachmentCell.image;
                
                // Note: we always attach as JPG regardless of the original format. This is because we don't have any mechanism for
                // generating NData for the original file, or even persisting the original filename. Something to fix in the future.
                [message attachFile:[attachmentImage JFIFData:0.6] withName:[NSString stringWithFormat:@"image%d.jpg", attachmentIndex]];
                
                [attrTextString removeAttribute:NSAttachmentAttributeName range:theEffectiveRange];
                NSAttributedString * attributedString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"{%d} ", attachmentIndex]];
                [attrTextString insertAttributedString:attributedString atIndex:index];
                
                ++attachmentIndex;
            }
        }
        while (index < theStringRange.length);
    }

    // Need to remove the NSAttachmentCharacter as the above won't do it for you.
    message.body = [[attrTextString string] stringByReplacingOccurrencesOfString:@"\uFFFC" withString:@""];
}

/* Called when the user makes any modifications to the text
 */
-(void)textDidChange:(NSNotification *)notification
{
    [messageWindow setDocumentEdited:YES];
}

/* Print the current message in the message window.
 */
-(IBAction)printDocument:(id)sender
{
    NSPrintInfo * printInfo = [NSPrintInfo sharedPrintInfo];
    NSPrintOperation * printOp;
    
    printOp = [NSPrintOperation printOperationWithView:textView printInfo:printInfo];
    [printOp setShowsPrintPanel:YES];
    [printOp runOperation];
}

/* Update the window title from the subject field
 */
-(void)updateTitle
{
    NSMutableString * title = [[NSMutableString alloc] init];
    if (_originalMessage != nil && _originalMessage.commentID > 0)
        [title appendFormat:NSLocalizedString(@"Reply to %lld", nil), _originalMessage.commentID];
    else
        [title appendString:NSLocalizedString(@"New Message", nil)];
    if (_originalMessage != nil)
    {
        Folder * topic = [CIX.folderCollection folderByID:_originalMessage.topicID];
        Folder * forum = [topic parentFolder];
        [title appendFormat:@" in %@ ∙ %@", forum.displayName, topic.displayName];
    }
    [messageWindow setTitle:title];
}

/* Do the menu initialisation when the user pulls down a menu item.
 */
-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    BOOL hasText = ![[textView string] isBlank];
    SEL theAction = [menuItem action];

    if (theAction == @selector(sendMessage:))
        return hasText;

    if (theAction == @selector(save:))
        return hasText;
    
    return YES;
}

/* Check the toolbar item and return YES if the item is enabled, NO otherwise.
 */
-(BOOL)validateToolbarItem:(CRToolbarItem *)toolbarItem
{
    BOOL hasText = ![[textView string] isBlank];
    
    if ([toolbarItem action] == @selector(sendMessage:))
        return hasText;
    
    if ([toolbarItem action] == @selector(save:))
        return hasText;
    
    if ([toolbarItem action] == @selector(quoteOriginal:))
        return _originalMessage != nil && _originalMessage.commentID > 0;
    
    return YES;
}

/* This method is required of NSToolbar delegates.  It takes an identifier, and returns the matching NSToolbarItem.
 * It also takes a parameter telling whether this toolbar item is going into an actual toolbar, or whether it's
 * going to be displayed in a customization palette.
 */
-(NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    CRToolbarItem *item = [[CRToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    if ([itemIdentifier isEqualToString:@"SendMessage"])
    {
        [item setLabel:NSLocalizedString(@"Send", nil)];
        [item setPaletteLabel:[item label]];
        [item setToolTip:NSLocalizedString(@"Send this message", nil)];
        [item compositeButtonImage:@"tbSend"];
        [item setTarget:self];
        [item setAction:@selector(sendMessage:)];
    }
    else if ([itemIdentifier isEqualToString:@"SaveAsDraft"])
    {
        [item setLabel:NSLocalizedString(@"Save", nil)];
        [item setPaletteLabel:[item label]];
        [item setToolTip:NSLocalizedString(@"Save this message", nil)];
        [item compositeButtonImage:@"tbSaveAsDraft"];
        [item setTarget:self];
        [item setAction:@selector(save:)];
    }
    else if ([itemIdentifier isEqualToString:@"QuoteOriginal"])
    {
        [item setLabel:NSLocalizedString(@"Quote", nil)];
        [item setPaletteLabel:[item label]];
        [item setToolTip:NSLocalizedString(@"Quote the original message", nil)];
        [item compositeButtonImage:@"tbQuote"];
        [item setTarget:self];
        [item setAction:@selector(quoteOriginal:)];
    }
    else if ([itemIdentifier isEqualToString:@"InsertImage"])
    {
        [item setLabel:NSLocalizedString(@"Insert Image", nil)];
        [item setPaletteLabel:[item label]];
        [item setToolTip:NSLocalizedString(@"Insert an image into this message", nil)];
        [item compositeButtonImage:@"tbImage"];
        [item setTarget:self];
        [item setAction:@selector(handleInsertImage:)];
    }
    return item;
}

/* This method is required of NSToolbar delegates.  It returns an array holding identifiers for the default
 * set of toolbar items.  It can also be called by the customization palette to display the default toolbar.
 */
-(NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return @[ @"SendMessage",
              @"SaveAsDraft",
              NSToolbarSpaceItemIdentifier,
              @"QuoteOriginal"
            ];
}

/* This method is required of NSToolbar delegates.  It returns an array holding identifiers for all allowed
 * toolbar items in this toolbar.  Any not listed here will not be available in the customization palette.
 */
-(NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return @[ NSToolbarSeparatorItemIdentifier,
              NSToolbarSpaceItemIdentifier,
              NSToolbarFlexibleSpaceItemIdentifier,
              @"SendMessage",
              @"SaveAsDraft",
              @"QuoteOriginal",
              @"InsertImage"
            ];
}
@end