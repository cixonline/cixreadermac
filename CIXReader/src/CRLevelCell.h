//
//  CRLevelCell.h
//  CIXReader
//
//  Created by Steve Palmer on 26/09/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

@interface CRLevelCell : NSTableCellView {
@private
    NSLevelIndicator * _levelIndicator;
}

@property(retain) IBOutlet NSLevelIndicator *levelIndicator;
@end
