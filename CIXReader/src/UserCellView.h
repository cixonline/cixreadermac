//
//  UserCellView.h
//  CIXReader
//
//  Created by Steve Palmer on 20/01/2015.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "CRRoundImageView.h"

@interface UserCellView : NSTableCellView

@property (retain, nonatomic) IBOutlet CRRoundImageView * image;
@property (retain, nonatomic) IBOutlet NSTextField * user;

@end
