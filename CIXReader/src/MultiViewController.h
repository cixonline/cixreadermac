//
//  MultiViewController.h
//  CIXReader
//
//  Created by Steve Palmer on 02/08/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

@protocol MultiViewInterface
-(BOOL)closeView:(BOOL)response;
@end

@interface MultiViewController : NSWindowController <NSToolbarDelegate> {
    IBOutlet NSWindow * _mainWindow;
    NSViewController * _previousView;
    NSDictionary * _viewsDictionary;
    NSMutableArray * _viewsIdentifiers;
    NSMutableDictionary * _viewsPanes;
    NSString * _selectedIdentifier;
    NSString * _configFilename;
    id _objectData;
    BOOL _isPrimaryNib;
}

// Accessors
-(id)initWithConfig:(NSString *)configFilename andData:(id)objectData;
-(void)closeAllViews:(BOOL)response;
@end
