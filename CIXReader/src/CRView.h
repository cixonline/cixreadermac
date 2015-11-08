//
//  CRView.h
//  CIXReader
//
//  Created by Steve Palmer on 03/11/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

@interface NSObject (CRViewDelegate)
-(BOOL)handleKeyDown:(unichar)keyChar withFlags:(NSUInteger)flags;
@end

@interface CRView : NSView

@property (readwrite, weak) IBOutlet id delegate;

@end
