//
//  Attachment.m
//  CIXClient
//
//  Created by Steve Palmer on 14/01/2016.
//  Copyright © 2016 CIXOnline Ltd. All rights reserved.
//

#import "Attachment.h"

@implementation Attachment

/* Return an array of all the attachments for the specified message
 */
+(NSArray *)attachmentsForMessage:(ID_type)messageID
{
    NSString * query = [NSString stringWithFormat:@" where messageID=%lld", messageID];
    return [Attachment allRowsWithQuery:query];
}

/** Return the raw data for the attachment.
 */
-(NSData *)data
{
    return [[NSData alloc] initWithBase64EncodedString:self.encodedData options:0];
}

/* Call superclass to get description format
 */
-(NSString *)description
{
    return [super description];
}
@end
