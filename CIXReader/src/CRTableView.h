//
//  CRTableView.h
//  CIXReader
//
//  Created by Steve Palmer on 03/11/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

@interface CRTableView : NSTableView

// Properties
@property (assign) NSInteger searchRow;

// Accessors
-(void)keyDown:(NSEvent *)theEvent;
-(void)setSelectedRow:(NSInteger)row;
@end

@interface NSObject (CRTableViewDelegate)
    -(BOOL)tableView:(CRTableView *)tableView handleKeyDown:(unichar)keyChar withFlags:(NSUInteger)flags;
@end


