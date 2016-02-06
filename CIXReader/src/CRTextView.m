//
//  CRTextView.m
//  CIXReader
//
//  Created by Steve Palmer on 06/02/2016.
//  Copyright © 2016 CIXOnline Ltd. All rights reserved.
//

#import "CRTextView.h"
#import "ImageExtensions.h"

@implementation CRTextView

/* Override paste to force all text to be pasted as plain text.
 */
-(IBAction)paste:(id)sender
{
    NSPasteboard * pasteboard = [NSPasteboard generalPasteboard];
    NSArray *classArray = [NSArray arrayWithObject:[NSImage class]];
    NSDictionary *options = [NSDictionary dictionary];

    if (![pasteboard canReadObjectForClasses:classArray options:options])
        [self pasteAsPlainText:sender];
    else
    {
        NSArray *objectsToPaste = [pasteboard readObjectsForClasses:classArray options:options];
        NSImage * pic = [[objectsToPaste objectAtIndex:0] constrain:300];

        NSTextAttachmentCell * attachmentCell = [[NSTextAttachmentCell alloc] initImageCell:pic];
        NSTextAttachment * attachment = [[NSTextAttachment alloc] init];
        [attachment setAttachmentCell: attachmentCell];
        NSAttributedString * attributedString = [NSAttributedString attributedStringWithAttachment: attachment];
        
        [self.textStorage insertAttributedString:attributedString atIndex:self.selectedRange.location];
    }
}
@end
