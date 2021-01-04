//
//  MailCellView.h
//  CIXReader
//
//  Created by Steve Palmer on 02/09/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

@interface MailCellView : NSTableCellView

@property (retain, nonatomic) IBOutlet NSImageView * image1;
@property (retain, nonatomic) IBOutlet NSImageView * image2;
@property (retain, nonatomic) IBOutlet NSImageView * mugshot;
@property (retain, nonatomic) IBOutlet NSTextField * author;
@property (retain, nonatomic) IBOutlet NSTextField * date;
@property (retain, nonatomic) IBOutlet NSTextField * subject;

@end
