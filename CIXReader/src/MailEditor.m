//
//  MailEditor.m
//  CIXReader
//
//  Created by Steve Palmer on 11/09/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "MailEditor.h"
#import "Constants.h"
#import "Preferences.h"
#import "StringExtensions.h"
#import "DateExtensions.h"
#import "CRToolbarItem.h"
#import "WindowCollection.h"

// Private interfaces
@interface MailEditor (Private)
    -(void)handleMessageFontChange:(NSNotification *)notification;
    -(void)handleSignaturesChange:(NSNotification *)notification;
    -(void)updateTitle;
    -(void)insertSignature:(NSString *)signatureTitle;
    -(void)reloadSignaturesList;
@end

@implementation MailEditor

/* Create a new message window to reply to the specified conversation.
 */
-(id)initWithConversation:(Conversation *)conversation
{
    if ((self = [self init]) != nil)
        _currentConversation = conversation;
    return self;
}

/* Create a new message window addressed to the specified
 * recipient.
 */
-(id)initWithRecipient:(NSString *)name
{
    if ((self = [self init]) != nil)
        _defaultRecipient = name;
    return self;
}

/* Create a new message window as a reply to the specified
 * message.
 */
-(id)initWithMessage:(Message *)message
{
    if ((self = [self init]) != nil)
        _messageToUse = message;
    return self;
}

/* Create a new message window.
 */
-(id)init
{
    return [super initWithWindowNibName:@"MailEditor"];
}

/* windowDidLoad
 */
-(void)windowDidLoad
{
    // Create the toolbar.
    NSToolbar * toolbar = [[NSToolbar alloc] initWithIdentifier:@"MA_MailEditorToolbar"];
    
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
    
    // Set the message font
    Preferences * prefs = [Preferences standardPreferences];
    NSFont * font = [NSFont fontWithName:[prefs messageFont] size:[prefs messageFontSize]];
    [self setMessageFont:font];
    
    // Make sure we're notified if the message font changes
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(handleMessageFontChange:) name:MA_Notify_MessageFontChange object:nil];
    
    // Also wants to be notified if the list of signatures changes
    [nc addObserver:self selector:@selector(handleSignaturesChange:) name:MA_Notify_SignaturesChange object:nil];

    // Text change notifications
    [nc addObserver:self selector:@selector(textDidChange:) name: NSTextDidChangeNotification object:textView];
    [nc addObserver:self selector:@selector(subjectDidChange:) name: NSControlTextDidChangeNotification object:subject];
    
    // Init the list of signatures
    _currentSignature = nil;
    [self reloadSignaturesList];
    
    // Fill out from a _messageToUse if one is provided
    if (_messageToUse != nil)
    {
        [recipient setStringValue:_messageToUse.author];
        [subject setStringValue:[NSString stringWithFormat:@"Re: %@", [_messageToUse.body.firstNonBlankLine truncateByWordWithLimit:80]]];
        [textView setString:_messageToUse.quotedBody];
        [[self window] makeFirstResponder:textView];
    }
    
    // If the text is empty, insert the default signature.
    NSString * defaultSignature = [prefs defaultSignature];
    if (![defaultSignature isEqualToString:[Signatures noSignaturesString]])
    {
        // Select default signature for this folder(conference)
        NSString * signature = defaultSignature;
        [signaturesList selectItemWithTitle:signature];
        [self insertSignature:signature];
    }
    
    // Set any default recipient and set the default focus to
    // the subject field.
    if (_defaultRecipient.length > 0)
    {
        [recipient setStringValue:_defaultRecipient];
        [[self window] makeFirstResponder:subject];
    }
    
    // If a current conversation is specified, both the recipient and
    // the subject are fixed, so pre-fill and disable those.
    if (_currentConversation != nil)
    {
        [subject setEditable:NO];
        [recipient setEditable:NO];
        
        [subject setBackgroundColor:[NSColor controlBackgroundColor]];
        [recipient setBackgroundColor:[NSColor controlBackgroundColor]];

        NSString * subjectString = [[_currentConversation subject] unquoteAttributes];
        
        if ([subjectString isBlank])
            subjectString = NSLocalizedString(@"(No subject)", nil);
        
        [subject setStringValue:subjectString];
        [recipient setStringValue:_currentConversation.author];

        [[self window] makeFirstResponder:textView];
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

/* insertSignature
 * This is the routine that actually inserts a signature into the text.
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

/* windowShouldClose
 * Since we established ourselves as the delegate for the window, we will
 * get the notifications when the window closes.
 */
-(BOOL)windowShouldClose:(NSNotification *)notification
{
    [self.window orderFront:self];
    if ([messageWindow isDocumentEdited])
    {
        NSAlert * alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:NSLocalizedString(@"Send", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Don't Send", nil)];
        [alert setMessageText:NSLocalizedString(@"Message not sent", nil)];
        [alert setInformativeText:NSLocalizedString(@"This message has not been sent. Are you sure you want to discard it?", nil)];
        [alert setAlertStyle:NSAlertStyleWarning];
        
        NSModalResponse returnCode = [alert runModal];
        
        if (returnCode == NSAlertFirstButtonReturn)
        {
            [self sendMessage:self];
            [messageWindow setDocumentEdited:NO];
        }
        if (returnCode == NSAlertThirdButtonReturn)
            [messageWindow setDocumentEdited:NO];
    }
    if (![messageWindow isDocumentEdited])
        return YES;

    return NO;
}

/* Save the message to the database and send it if we're online.
 */
-(void)sendMessage:(id)sender
{
    NSDate * now = [NSDate localDate];
    if (_currentConversation == nil)
    {
        _currentConversation = [Conversation new];
        [_currentConversation setSubject:[subject stringValue]];
        [_currentConversation setAuthor:CIX.username];
        [_currentConversation setDate:now];
    }
    
    // Add this message to the end of the conversation.
    if (_currentMessage == nil)
    {
        _currentMessage = [MailMessage new];
        [_currentMessage setRecipient:(_currentConversation.ID > 0) ? CIX.username : [recipient stringValue]];
        [_currentMessage setBody:[textView string]];
        [_currentMessage setConversationID:[_currentConversation ID]];
        [_currentMessage setDate:now];
        [CIX.conversationCollection add:_currentConversation withMessage:_currentMessage];
    }
    
    [messageWindow setDocumentEdited:NO];
    [messageWindow performClose:self];
}

/* Called when the user makes any modifications to the subject field
 */
-(void)subjectDidChange:(NSNotification *)notification
{
    [messageWindow setDocumentEdited:YES];
    [self updateTitle];
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
    if (_currentConversation != nil)
    {
        NSString * title = [NSString stringWithFormat:NSLocalizedString(@"Reply to %@", nil), [subject stringValue]];
        [messageWindow setTitle:title];
    }
    else
    {
        BOOL hasSubject = ![[subject stringValue] isBlank];
        [messageWindow setTitle:hasSubject ? [subject stringValue] : NSLocalizedString(@"New PMessage", nil)];
    }
}

/* Do the menu initialisation when the user pulls down a menu item.
 */
-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    BOOL hasRecipient = ![[recipient stringValue] isBlank];
    BOOL hasSubject = ![[subject stringValue] isBlank];
    BOOL hasText = ![[textView string] isBlank];
    SEL theAction = [menuItem action];
    
    if (theAction == @selector(sendMessage:))
        return hasRecipient && hasSubject && hasText;
    
    return YES;
}

/* Check the toolbar item and return YES if the item is enabled, NO otherwise.
 */
-(BOOL)validateToolbarItem:(CRToolbarItem *)toolbarItem
{
    BOOL hasRecipient = ![[recipient stringValue] isBlank];
    BOOL hasSubject = ![[subject stringValue] isBlank];
    BOOL hasText = ![[textView string] isBlank];
    
    if ([toolbarItem action] == @selector(sendMessage:))
        return hasRecipient && hasSubject && hasText;

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
    return item;
}

/* This method is required of NSToolbar delegates.  It returns an array holding identifiers for the default
 * set of toolbar items.  It can also be called by the customization palette to display the default toolbar.
 */
-(NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return @[ @"SendMessage" ];
}

/* This method is required of NSToolbar delegates.  It returns an array holding identifiers for all allowed
 * toolbar items in this toolbar.  Any not listed here will not be available in the customization palette.
 */
-(NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return @[ NSToolbarSpaceItemIdentifier,
              NSToolbarFlexibleSpaceItemIdentifier,
              @"SendMessage",
            ];
}
@end
