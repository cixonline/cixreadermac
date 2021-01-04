//
//  TaggedMailMessage.m
//  CIXReader
//
//  Created by Steve Palmer on 02/09/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "TaggedMailMessage.h"
#import "StyleController.h"
#import "StringExtensions.h"

@implementation MailMessage (TaggedMailMessage)

/* Return the raw text to be displayed in the absence of a template.
 */
-(NSString *)unformattedText
{
    return self.body;
}

/* Returns a custom image tag representing the message author. This will
 * have been resolved earlier in the HTML load code that maps image tags
 * to actual images.
 */
-(NSString *)tagImage:(StyleController *)styleController
{
    return [styleController imageFromTag:self.recipient];
}

/* Returns the message remote ID.
 */
-(NSString *)tagID:(StyleController *)styleController
{
    return @"";
}

/* Returns the message comment ID.
 */
-(NSString *)tagCommentID:(StyleController *)styleController
{
    return @"";
}

/* Returns the message body.
 * We first format it to render correctly in an HTML block.
 */
-(NSString *)tagBody:(StyleController *)styleController
{
    return [styleController htmlFromTag:self.body];
}

/* Returns the message author as a safe string.
 */
-(NSString *)tagAuthor:(StyleController *)styleController
{
    return [styleController stringFromTag:self.recipient];
}

/* Returns the message date.
 */
-(NSString *)tagDate:(StyleController *)styleController
{
    return [styleController dateFromTag:self.date];
}

/* Returns the message subject.
 */
-(NSString *)tagSubject:(StyleController *)styleController
{
    return [self.body.firstNonBlankLine truncateByWordWithLimit:80];
}

/* Reply ID is always blank for mail messages.
 */
-(NSString *)tagInReplyTo:(StyleController *)styleController
{
    return @"";
}

/* Returns the full address of this mail message.
 */
-(NSString *)tagLink:(StyleController *)styleController
{
    return @"";
}
@end
