//
//  RulesPreferences.h
//  CIXReader
//
//  Created by Steve Palmer on 26/11/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "Rule.h"

@interface RulesPreferences : NSViewController {
    IBOutlet NSTableView * rulesList;
    IBOutlet NSButton * newRuleButton;
    IBOutlet NSButton * editRuleButton;
    IBOutlet NSButton * deleteRuleButton;
    IBOutlet NSButton * saveRuleButton;
    IBOutlet NSButton * cancelRuleButton;
    IBOutlet NSPredicateEditor * ruleEditor;
    IBOutlet NSTextField * ruleTitle;
    IBOutlet NSWindow * ruleEditorWindow;
    IBOutlet NSLayoutConstraint * ruleEditorHeight;
    IBOutlet NSButton * markReadAction;
    IBOutlet NSButton * markPriorityAction;
    IBOutlet NSButton * markIgnoreAction;
    IBOutlet NSButton * markFlagAction;
    
    NSArray * _arrayOfRules;
    Rule * _currentRule;
    BOOL _didInitialise;
}

// Accessors
-(IBAction)handleNewRuleButton:(id)sender;
-(IBAction)handleEditRuleButton:(id)sender;
-(IBAction)handleDeleteRuleButton:(id)sender;
-(IBAction)handleResetButton:(id)sender;
-(IBAction)saveRule:(id)sender;
-(IBAction)cancelRule:(id)sender;
-(IBAction)ruleEditorAction:(id)sender;
-(IBAction)actionStateChange:(id)sender;
@end
