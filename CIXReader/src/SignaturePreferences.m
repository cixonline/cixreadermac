//
//  SignaturePreferences.m
//  CIXReader
//
//  Created by Steve Palmer on 04/11/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "SignaturePreferences.h"
#import "StringExtensions.h"
#import "Signatures.h"
#import "Preferences.h"

@implementation SignaturePreferences

/* Initialize the class
 */
-(id)initWithObject:(id)data
{
    return [super initWithNibName:@"SignaturePreferences" bundle:nil];
}

/* First time window load initialisation. Since preferences could potentially be
 * changed while the Preferences window is closed, initialise the controls in the
 * initializePreferences function instead.
 */
-(void)awakeFromNib
{
    if (!_didInitialise)
    {
        [self initializePreferences];
        _didInitialise = YES;
    }
}

/* Set the preference settings from the user defaults.
 */
-(void)initializePreferences
{
    _arrayOfSignatures = [[Signatures defaultSignatures] signatureTitles];
    [deleteSignatureButton setEnabled:NO];
    [editSignatureButton setEnabled:NO];
    _signatureBeingEdited = nil;
    
    // Load the list of default signatures and select the actual default
    Preferences * prefs = [Preferences standardPreferences];
    
    [defaultSignature addItemsWithTitles:_arrayOfSignatures];
    [defaultSignature selectItemWithTitle:[prefs defaultSignature]];

    [signatureText setAutomaticQuoteSubstitutionEnabled:NO];
    [signatureText setAutomaticDashSubstitutionEnabled:NO];
    
    [signaturesList setTarget:self];
    [signaturesList setDoubleAction:@selector(editSignature:)];

    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(handleTextDidChange:) name:NSControlTextDidChangeNotification object:signatureTitle];
}

/* Datasource for the table view. Return the total number of signatures in the
 * arrayOfSignatures array.
 */
-(NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [_arrayOfSignatures count];
}

/* Called by the table view to obtain the object at the specified column and row. This is
 * called often so it needs to be fast.
 */
-(id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    return _arrayOfSignatures[rowIndex];
}

/* Handle the selection changing in the table view.
 */
-(void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    NSInteger row = signaturesList.selectedRow;
    [deleteSignatureButton setEnabled:(row >= 0)];
    [editSignatureButton setEnabled:(row >= 0)];
}

/* Called when the user clicks the New Signature button. Start the UI to create
 * a new signature.
 */
-(IBAction)newSignature:(id)sender
{
    _signatureBeingEdited = nil;
    
    [signatureText setString:@""];
    [signatureTitle setStringValue:@""];
    [saveSignatureButton setEnabled:NO];
    [[signaturesList window] beginSheet:signatureEditor
                      completionHandler:^(NSModalResponse returnCode) {
                          [self signatureSheetEnd:[self->signaturesList window] returnCode:returnCode contextInfo:nil];
    }];
}

/* Called when the user either clicks the Edit button or double-clicks an existing
 * signature. Start the UI to edit the signature.
 */
-(IBAction)editSignature:(id)sender
{
    if (signaturesList.selectedRow >= 0)
    {
        NSString * title = _arrayOfSignatures[signaturesList.selectedRow];
        NSString * text = [[Signatures defaultSignatures] signatureForTitle:title];
        
        _signatureBeingEdited = title;
        
        [signatureText setString:text];
        [signatureTitle setStringValue:title];
        [saveSignatureButton setEnabled:YES];
        [[signaturesList window] beginSheet:signatureEditor
                          completionHandler:^(NSModalResponse returnCode) {
                              [self signatureSheetEnd:[self->signaturesList window] returnCode:returnCode contextInfo:nil];
                          }];
    }
}

/* Called when the user clicks the Delete signature button. Drop the selected signature
 * from the list and also drop it from the available default signatures. If this signature was
 * originally our default signature, the new default signature should become "None".
 */
-(IBAction)deleteSignature:(id)sender
{
    NSString * titleOfSignatureToDelete = _arrayOfSignatures[signaturesList.selectedRow];
    
    // Call a common function to both remove the signature and fix up the default
    // signatures if needed.
    [self removeSignature:titleOfSignatureToDelete];
    [self reloadSignatures];
    
    // Give all open message windows a chance to refresh their signature drop down list.
    [[NSNotificationCenter defaultCenter] postNotificationName:MA_Notify_SignaturesChange object:nil];
}

/* Called when the user clicks Save
 */
-(IBAction)saveSignature:(id)sender
{
    [[signaturesList window] endSheet:signatureEditor returnCode:NSModalResponseOK];
}

/* Just close the signature editor window.
 */
-(IBAction)cancelSignature:(id)sender
{
    [[signaturesList window] endSheet:signatureEditor returnCode:NSModalResponseCancel];
}

/* Called when the Edit Signature sheet is dismissed. The returnCode is NSOKButton if the Save
 * button was pressed, or NSCancelButton otherwise.
 */
-(void)signatureSheetEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSModalResponseOK)
    {
        NSString * title = [signatureTitle stringValue];
        NSString * text = [NSString stringWithString:[signatureText string]];
        
        // If we changed the signature title, remove the old one.
        if (_signatureBeingEdited)
        {
            if (![_signatureBeingEdited isEqualToString:title])
                [self removeSignature:_signatureBeingEdited];
        }
        
        [[Signatures defaultSignatures] addSignature:title withText:text];
        [self reloadSignatures];
        
        // Add this to the default signature collection
        [defaultSignature addItemWithTitle:title];
        [defaultSignature selectItemWithTitle:[[Preferences standardPreferences] defaultSignature]];
        
        // Select the newly added signature for convenience.
        NSInteger row = [_arrayOfSignatures indexOfObject:title];
        [signaturesList selectRowIndexes: [NSIndexSet indexSetWithIndex:(NSUInteger)row] byExtendingSelection:NO];
        
        // Give all open message windows a chance to refresh their signature drop down list.
        [[NSNotificationCenter defaultCenter] postNotificationName:MA_Notify_SignaturesChange object:title];
    }
    [signatureEditor orderOut:self];
    [[signaturesList window] makeKeyAndOrderFront:self];
}

/* Remove the specified signature from the list AND remove it from the list of default
 * signatures.
 */
-(void)removeSignature:(NSString *)title
{
    NSString * currentDefault = [defaultSignature titleOfSelectedItem];
    if ([currentDefault isEqualToString:title])
    {
        [[Preferences standardPreferences] setDefaultSignature:[Signatures noSignaturesString]];
        [defaultSignature selectItemWithTitle:[Signatures noSignaturesString]];
    }
    [defaultSignature removeItemWithTitle:title];
    
    // Now actually remove the signature.
    [[Signatures defaultSignatures] removeSignature:title];
}

/* The user selected a different default signature so save it.
 */
-(IBAction)selectDefaultSignature:(id)sender
{
    NSString * newDefaultSignature = [sender titleOfSelectedItem];
    [[Preferences standardPreferences] setDefaultSignature:newDefaultSignature];
}

/* Re-initialise the arrayOfSignatures.
 */
-(void)reloadSignatures
{
    _arrayOfSignatures = [[Signatures defaultSignatures] signatureTitles];
    [signaturesList reloadData];
}

/* This function is called when the contents of the title field is changed.
 * We disable the Save button if the title field is empty or enable it otherwise.
 */
-(void)handleTextDidChange:(NSNotification *)aNotification
{
    NSString * title = [signatureTitle stringValue];
    [saveSignatureButton setEnabled:![title isBlank]];
}
@end
