//
//  RulesPreferences.m
//  CIXReader
//
//  Created by Steve Palmer on 26/11/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "RulesPreferences.h"
#import "StringExtensions.h"
#import "CIX.h"

@implementation RulesPreferences

/* Initialize the class
 */
-(id)initWithObject:(id)data
{
    return [super initWithNibName:@"RulesPreferences" bundle:nil];
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
    [deleteRuleButton setEnabled:NO];
    [editRuleButton setEnabled:NO];
    
    _arrayOfRules = [CIX.ruleCollection allRules];
    
    // Key values
    // These are hard-coded because we only want to expose a limited set of
    // properties to rules to avoid complications.
    NSArray * stringKeyPaths = @[[NSExpression expressionForKeyPath:@"author"],
                                 [NSExpression expressionForKeyPath:@"body"],
                                 [NSExpression expressionForKeyPath:@"subject"],
                                 [NSExpression expressionForKeyPath:@"parent.author"],
                                 [NSExpression expressionForKeyPath:@"parent.body"],
                                 [NSExpression expressionForKeyPath:@"parent.subject"],
                                 [NSExpression expressionForKeyPath:@"topic.name"],
                                 [NSExpression expressionForKeyPath:@"forum.name"]
                                 ];
    
    NSArray * boolKeyPaths = @[[NSExpression expressionForKeyPath:@"priority"],
                          [NSExpression expressionForKeyPath:@"ignored"],
                          [NSExpression expressionForKeyPath:@"parent.priority"],
                          [NSExpression expressionForKeyPath:@"parent.ignored"],
                          [NSExpression expressionForKeyPath:@"isMine"],
                          [NSExpression expressionForKeyPath:@"isPseudo"]
                          ];

    // List of all possible rule operators
    NSArray * stringOperators = @[@(NSEqualToPredicateOperatorType),
                           @(NSNotEqualToPredicateOperatorType),
                           @(NSBeginsWithPredicateOperatorType),
                           @(NSEndsWithPredicateOperatorType),
                           @(NSContainsPredicateOperatorType)];

    // List of all possible rule operators
    NSArray * boolOperators = @[@(NSEqualToPredicateOperatorType),
                                  @(NSNotEqualToPredicateOperatorType)];

    NSPredicateEditorRowTemplate * stringTemplate =
        [[NSPredicateEditorRowTemplate alloc] initWithLeftExpressions:stringKeyPaths
          rightExpressionAttributeType:NSStringAttributeType
                              modifier:NSDirectPredicateModifier
                             operators:stringOperators
                               options:(NSCaseInsensitivePredicateOption | NSDiacriticInsensitivePredicateOption)];
    
    NSPredicateEditorRowTemplate * boolTemplate =
    [[NSPredicateEditorRowTemplate alloc] initWithLeftExpressions:boolKeyPaths
                                     rightExpressionAttributeType:NSBooleanAttributeType
                                                         modifier:NSDirectPredicateModifier
                                                        operators:boolOperators
                                                          options:0];
    
    // List of possible component types.
    NSArray * compoundTypes = @[@(NSNotPredicateType),
                               @(NSAndPredicateType),
                               @(NSOrPredicateType)];
    NSPredicateEditorRowTemplate * compound = [[NSPredicateEditorRowTemplate alloc] initWithCompoundTypes:compoundTypes];
    
    [ruleEditor setRowTemplates:@[boolTemplate, stringTemplate, compound]];
    
    [rulesList setTarget:self];
    [rulesList setDoubleAction:@selector(handleEditRuleButton:)];
    
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(handleTextDidChange:) name:NSControlTextDidChangeNotification object:ruleTitle];
    [nc addObserver:self selector:@selector(handleRuleAdded:) name:MARuleAdded object:nil];
}

/* Datasource for the table view. Return the total number of signatures in the
 * arrayOfSignatures array.
 */
-(NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [_arrayOfRules count];
}

/* Called by the table view to obtain the object at the specified column and row. This is
 * called often so it needs to be fast.
 */
-(id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    Rule * rule = (Rule *)_arrayOfRules[rowIndex];
    if ([aTableColumn.identifier isEqualToString:@"Active"])
        return @(rule.active);

    return rule.title;
}

/* Called when the user clicks a check cell.
 */
-(void)tableView:(NSTableView *)aTableView setObjectValue:(id)value forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if ([aTableColumn.identifier isEqualToString:@"Active"])
    {
        Rule * rule = (Rule *)_arrayOfRules[rowIndex];
        rule.active = [value intValue];
        [CIX.ruleCollection save];
        [aTableView reloadData];
    }
}

/* Handle the selection changing in the table view.
 */
-(void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    NSInteger row = [rulesList selectedRow];
    [deleteRuleButton setEnabled:(row >= 0)];
    [editRuleButton setEnabled:(row >= 0)];
}

/* Invoke logic to create a new, blank, rule.
 */
-(void)handleNewRuleButton:(id)sender
{
    _currentRule = nil;
    
    NSPredicate * defaultPred = [NSPredicate predicateWithFormat:@"subject=''"];
    
    [ruleTitle setStringValue:@""];
    [ruleEditor setObjectValue:[NSCompoundPredicate orPredicateWithSubpredicates:@[defaultPred]]];
    [self ruleEditorAction:self];
    
    [markReadAction setState:NSOnState];
    [markPriorityAction setState:NSOffState];
    [markIgnoreAction setState:NSOffState];
    [markFlagAction setState:NSOffState];

    [saveRuleButton setEnabled:YES];
    
    [ruleEditorWindow makeFirstResponder:ruleTitle];

    [NSApp beginSheet:ruleEditorWindow
       modalForWindow:[rulesList window]
        modalDelegate:self
       didEndSelector:@selector(rulesSheetEnd:returnCode:contextInfo:)
          contextInfo:nil];
}

/* Invoke logic to edit the existing rule.
 */
-(void)handleEditRuleButton:(id)sender
{
    _currentRule = _arrayOfRules[rulesList.selectedRow];

    [ruleTitle setStringValue:_currentRule.title];
    [ruleEditor setObjectValue:_currentRule.predicate];
    [self ruleEditorAction:self];
    
    [markReadAction setState:((_currentRule.actionCode & (CC_Rule_Unread|CC_Rule_Clear)) == (CC_Rule_Unread|CC_Rule_Clear)) ? NSOnState : NSOffState];
    [markPriorityAction setState:(_currentRule.actionCode & CC_Rule_Priority) ? NSOnState : NSOffState];
    [markIgnoreAction setState:(_currentRule.actionCode & CC_Rule_Ignored) ? NSOnState : NSOffState];
    [markFlagAction setState:(_currentRule.actionCode & CC_Rule_Flag) ? NSOnState : NSOffState];
    
    [saveRuleButton setEnabled:NO];
    
    [NSApp beginSheet:ruleEditorWindow
       modalForWindow:[rulesList window]
        modalDelegate:self
       didEndSelector:@selector(rulesSheetEnd:returnCode:contextInfo:)
          contextInfo:nil];
}

/* Called when the user clicks Save
 */
-(IBAction)saveRule:(id)sender
{
    [NSApp endSheet:ruleEditorWindow returnCode:NSOKButton];
}

/* Just close the rule editor window.
 */
-(IBAction)cancelRule:(id)sender
{
    [NSApp endSheet:ruleEditorWindow returnCode:NSCancelButton];
}

/* Called when the Edit Rule sheet is dismissed. The returnCode is NSOKButton if the Save
 * button was pressed, or NSCancelButton otherwise.
 */
-(void)rulesSheetEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSOKButton)
    {
        NSString * title = [ruleTitle stringValue];
        NSPredicate * predicate = [ruleEditor objectValue];
        
        if (_currentRule == nil)
        {
            _currentRule = [Rule new];
            [CIX.ruleCollection addRule:_currentRule];
        }
        _currentRule.title = title;
        _currentRule.predicate = predicate;
        _currentRule.active = YES;
        
        NSUInteger actionCode = 0;
        if ([markReadAction state] == NSOnState)
            actionCode |= CC_Rule_Unread|CC_Rule_Clear;
        if ([markPriorityAction state] == NSOnState)
            actionCode |= CC_Rule_Priority;
        if ([markIgnoreAction state] == NSOnState)
            actionCode |= CC_Rule_Ignored;
        if ([markFlagAction state] == NSOnState)
            actionCode |= CC_Rule_Flag;
        _currentRule.actionCode = actionCode;
        [CIX.ruleCollection save];

        if (_currentRule != nil)
        {
            NSInteger index = [_arrayOfRules indexOfObject:_currentRule];
            [rulesList reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:index] columnIndexes:[NSIndexSet indexSetWithIndex:1]];
        }
    }
    [ruleEditorWindow orderOut:self];
    [[rulesList window] makeKeyAndOrderFront:self];
}

/* Invoke logic to delete the selected rule.
 */
-(void)handleDeleteRuleButton:(id)sender
{
    NSInteger index = rulesList.selectedRow;
    
    Rule * rule = _arrayOfRules[index];
    [CIX.ruleCollection deleteRule:rule];
    [CIX.ruleCollection save];

    _arrayOfRules = [CIX.ruleCollection allRules];
    [self reloadRules:index];
}

-(void)reloadRules:(NSInteger)selectedRow
{
    [rulesList reloadData];
    
    if (selectedRow >= _arrayOfRules.count)
        selectedRow = _arrayOfRules.count - 1;
    [rulesList selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
    
    [deleteRuleButton setEnabled:_arrayOfRules.count > 0];
    [editRuleButton setEnabled:_arrayOfRules.count > 0];
}

/* Invoke logic to reset all rules.
 */
-(void)handleResetButton:(id)sender
{
    NSInteger returnCode = NSRunAlertPanel(
           NSLocalizedString(@"Reset All Rules", nil),
           NSLocalizedString(@"This will reset all rules back to the CIXReader defaults and discard all custom modifications. Are you sure?", nil),
           NSLocalizedString(@"Yes", nil),
           NSLocalizedString(@"No", nil),
           nil);

    if (returnCode == NSAlertDefaultReturn)
    {
        [CIX.ruleCollection reset];
        _arrayOfRules = [CIX.ruleCollection allRules];
        [self reloadRules:0];
    }
}

/* Catch the Add Row action to expand the height of the rule editor to accommodate the
 * new row.
 */
-(IBAction)ruleEditorAction:(id)sender
{
    NSInteger newRowCount = [ruleEditor numberOfRows];
    NSInteger rowHeight = [ruleEditor rowHeight];
    [[ruleEditorHeight animator] setConstant:rowHeight*newRowCount];
    
    [self refreshRuleEditorButtons];
}

/* Respond to the notification that a new rule has been added and
 * refresh the list.
 */
-(void)handleRuleAdded:(NSNotification *)nc
{
    _arrayOfRules = [CIX.ruleCollection allRules];
    
    NSInteger index = [_arrayOfRules indexOfObject:nc.object];
    [self reloadRules:index];
}

/* This function is called when the contents of the title field is changed.
 * We disable the Save button if the title field is empty or enable it otherwise.
 */
-(void)handleTextDidChange:(NSNotification *)aNotification
{
    [self refreshRuleEditorButtons];
}

-(IBAction)actionStateChange:(id)sender
{
    [self refreshRuleEditorButtons];
}

-(void)refreshRuleEditorButtons
{
    NSString * title = [ruleTitle stringValue];
    [saveRuleButton setEnabled:![title isBlank]];
}
@end
