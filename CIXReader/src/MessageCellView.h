//
//  MessageCellView.h
//  CIXReader
//
//  Created by Steve Palmer on 30/10/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "CRImageView.h"

@interface MessageCellView : NSTableCellView

@property (retain, nonatomic) IBOutlet NSLayoutConstraint * spacerWidth;
@property (retain, nonatomic) IBOutlet NSLayoutConstraint * expanderWidth;
@property (retain, nonatomic) IBOutlet CRImageView * image1;
@property (retain, nonatomic) IBOutlet CRImageView * image2;
@property (retain, nonatomic) IBOutlet NSImageView * mugshot;
@property (retain, nonatomic) IBOutlet NSTextField * author;
@property (retain, nonatomic) IBOutlet NSTextField * date;
@property (retain, nonatomic) IBOutlet NSTextField * subject;
@property (retain, nonatomic) IBOutlet NSTextField * remoteID;
@property (retain, nonatomic) IBOutlet NSImageView * expander;

@end
