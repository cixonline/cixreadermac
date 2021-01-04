//
//  TaggedMessage.m
//  CIXReader
//
//  Created by Steve Palmer on 24/10/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "TaggedMessage.h"
#import "Folder.h"
#import "StyleController.h"
#import "StringExtensions.h"

@implementation Message (TaggedMessage)

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
    return [styleController imageFromTag:self.author];
}

/* Returns the message remote ID.
 */
-(NSString *)tagID:(StyleController *)styleController
{
    return self.isPseudo ? @"Draft" : [NSString stringWithFormat:@"%i", self.remoteID];
}

/* Returns the message comment ID.
 */
-(NSString *)tagCommentID:(StyleController *)styleController
{
    return self.commentID > 0 ? [NSString stringWithFormat:@"%i", self.commentID] : @"";
}

/* Returns the message body.
 * We first format it to render correctly in an HTML block.
 */
-(NSString *)tagBody:(StyleController *)styleController
{
    return [styleController htmlFromTag:self.bodyWithAttachments];
}

/* Returns the message author as a safe string.
 */
-(NSString *)tagAuthor:(StyleController *)styleController
{
    return [styleController stringFromTag:self.author];
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
    return [[self.body.firstNonBlankLine quoteAttributes] truncateByWordWithLimit:80];
}

/* Returns the message comment ID.
 */
-(NSString *)tagInReplyTo:(StyleController *)styleController
{
    return self.commentID > 0 ? [NSString stringWithFormat:@"cix:%@/%@:%d", self.forum.name, self.topic.name, self.commentID] : @"";
}

/* Returns the full address of this message.
 */
-(NSString *)tagLink:(StyleController *)styleController
{
    return [NSString stringWithFormat:@"cix:%@/%@:%d", self.forum.name, self.topic.name, self.remoteID];
}
@end
