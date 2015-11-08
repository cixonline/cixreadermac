//
//  CRFolderView.h
//  CIXReader
//
//  Created by Steve Palmer on 20/08/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

@interface CRFolderView : NSOutlineView {
	BOOL _useTooltips;
}

// Accessors
-(void)setEnableTooltips:(BOOL)flag;
-(void)buildTooltips;
@end

@interface NSObject (CRFolderViewDataSource)
	-(NSString *)outlineView:(CRFolderView *)outlineView tooltipForItem:(id)item;
    -(void)outlineView:(CRFolderView *)outlineView menuWillAppear:(NSEvent *)theEvent;
    -(void)outlineView:(CRFolderView *)outlineView dragCompleted:(BOOL)deposited;
@end


