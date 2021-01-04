//
//  Rule.h
//  CIXClient
//
//  Created by Steve Palmer on 26/11/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "Message.h"

#define CC_Rule_Unread           0x0001
#define CC_Rule_Priority         0x0002
#define CC_Rule_Ignored          0x0004
#define CC_Rule_Flag             0x0008
#define CC_Rule_Clear            0x1000

/** The Rule class
 
 The Rule class defines a single rule that contains a predicate that matches against
 a message and a block handler that is run if the predicate matches.
 */
@interface Rule : NSObject<NSCoding>

/** Active
 
 Specifies whether or not this rule is active. In-active rules are ignored during
 rule processing.
 */
@property (assign, readwrite) BOOL active;

/** Rule title
 
 The rule title is an unique and user-friendly title for the rule that appears in
 the rule editor.
 */
@property (atomic, readwrite) NSString * title;

/** Predicate

 The predicate is an NSPredicate object that contains conditions against which the
 Message must match in order for the handler to run against that message.
 */
@property (atomic, readwrite) NSPredicate * predicate;

/** ActionCode
 
 The action code defines the combination of actions that are applied to the message
 if the rule matches that message. Refer to the CC_Rule definitions at the head
 of this file for the current list of action code bit fields.
 */
@property (assign, readwrite) NSUInteger actionCode;

@end
