//
//  MailMessage.m
//  CIXClient
//
//  Created by Steve Palmer on 01/09/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "CIX.h"
#import "MailMessage.h"
#import "DateExtensions.h"
#import "StringExtensions.h"

@implementation MailMessage

/* Return an empty conversation. The caller must fill out the recipient
 * and subject fields, and add it to the collection.
 */
-(id)init
{
    if ((self = [super init]) != nil)
    {
        self.ID = 0;
        self.remoteID = 0;
        self.date = [NSDate localDate];
        self.conversationID = 0;
    }
    return self;
}

/* Return whether this is a draft message. A draft
 * message is one which has no remote ID yet and thus
 * has not yet been posted.
 */
-(BOOL)isDraft
{
    return self.remoteID == 0;
}

/* Return whether this message was posted by the authenticated
 * user.
 */
-(BOOL)isMine
{
    return [self.recipient isEqualToString:CIX.username];
}

/* Call superclass to get description format
 */
-(NSString *)description
{
    return [super description];
}
@end
