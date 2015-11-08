//
//  MultiViewController.m
//  CIXReader
//
//  Created by Steve Palmer on 02/08/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "MultiViewController.h"
#include <objc/runtime.h>

@interface MultiViewController (Private)
-(void)selectPane:(NSString *)identifier;
@end

@interface NSToolbar (NSToolbarPrivate)
-(NSView *)_toolbarView;
@end

@implementation MultiViewController

/* Initialises a new instance of the MultiViewController object.
 */
-(id)initWithConfig:(NSString *)configFilename andData:(id)objectData
{
    NSRect windowRect = NSMakeRect(100, 100, 240, 240);
    NSUInteger windowStyle = (NSTitledWindowMask | NSClosableWindowMask | NSUnifiedTitleAndToolbarWindowMask);
    
    NSWindow * mainWindow = [[NSWindow alloc] initWithContentRect:windowRect styleMask:windowStyle backing:NSBackingStoreBuffered defer:NO];
    if ((self = [super initWithWindow:mainWindow]) != nil)
    {
        _mainWindow = mainWindow;
        _viewsDictionary = nil;
        _viewsPanes = nil;
        _viewsIdentifiers = nil;
        _selectedIdentifier = nil;
        _configFilename = configFilename;
        _objectData = objectData;
        _isPrimaryNib = YES;
        
        [self windowDidLoad];
        [_mainWindow makeKeyAndOrderFront:self];
    }
    return self;
}

/* Do the things that only make sense after the window file is loaded.
 */
-(void)windowDidLoad
{
    // We get called for all view NIBs, so don't handle those or we'll stack overflow.
    if (!_isPrimaryNib)
        return;
    
    // Load the NIBs using the plist to locate them and build the
    // array of identifiers.
    NSBundle * thisBundle = [NSBundle bundleForClass:[self class]];
    NSString * pathToPList = [thisBundle pathForResource:_configFilename ofType:@""];
    NSAssert(pathToPList != nil, @"Missing %@ in build", _configFilename);
    
    // Load the dictionary and sort the keys by name to create the ordered
    // identifiers for each pane.
    _viewsDictionary = [NSDictionary dictionaryWithContentsOfFile:pathToPList];
    
    _viewsIdentifiers = [NSMutableArray array];
    for (NSString * viewItem in _viewsDictionary.allKeys)
    {
        if ([[_viewsDictionary valueForKey:viewItem] isKindOfClass:[NSDictionary class]])
            [_viewsIdentifiers addObject:viewItem];
    }
    [_viewsIdentifiers sortUsingSelector:@selector(caseInsensitiveCompare:)];
    NSAssert([_viewsIdentifiers count] > 0, @"Empty %@ file", _configFilename);
    
    // Set the title
    [_mainWindow setTitle:NSLocalizedString([_viewsDictionary valueForKey:@"Title"], nil)];
    
    // Create the toolbar
    NSToolbar * toolbar = [[NSToolbar alloc] initWithIdentifier:@"CR_MV_Toolbar"];
    [toolbar setAllowsUserCustomization:NO];
    [toolbar setAutosavesConfiguration:NO];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
    [toolbar setDelegate:self];
    [_mainWindow setToolbar:toolbar];
    
    // Hide the toolbar pill button
    [[_mainWindow standardWindowButton:NSWindowToolbarButton] setFrame:NSZeroRect];
    [_mainWindow setHasShadow:YES];
    
    // Create an empty view
    _blankView = [[NSView alloc] initWithFrame:[[_mainWindow contentView] frame]];
    
    // Array of pane objects
    _viewsPanes = [[NSMutableDictionary alloc] init];
    
    // Center the window
    [_mainWindow center];
    
    // Primary NIB is done.
    _isPrimaryNib = NO;
    
    // Select the first pane
    [self selectPane:_viewsIdentifiers[0]];
}

/* Creates and returns an NSToolbarItem for the specified identifier.
 */
-(NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem * newItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    NSDictionary * viewsItem = _viewsDictionary[itemIdentifier];
    [newItem setLabel:NSLocalizedString([viewsItem valueForKey:@"Title"], nil)];
    [newItem setTarget:self];
    [newItem setAction:@selector(viewPaneSelection:)];
    
    NSString * viewImage = [viewsItem valueForKey:@"Image"];
    if (viewImage != nil)
        [newItem setImage:[NSImage imageNamed:viewImage]];
    return newItem;
}

/* Change the active pane.
 */
-(IBAction)viewPaneSelection:(id)sender
{
    NSToolbar * toolbar = [_mainWindow toolbar];
    [self selectPane:[toolbar selectedItemIdentifier]];
}

/* Call every view's closeView method to give it a chance to save
 */
-(void)closeAllViews:(BOOL)response
{
    for (NSWindowController<MultiViewInterface> * pane in _viewsPanes.allValues)
    {
        BOOL doContinue = [pane closeView:response];
        if (!doContinue)
            return;
    }
    
    [NSApp stopModalWithCode:response];
}

/* Activate the pane with the given identifier. Resize the main
 * window to accommodate the pane contents.
 */
-(void)selectPane:(NSString *)identifier
{
    NSDictionary * viewItem = _viewsDictionary[identifier];
    NSAssert(viewItem != nil, @"Not a valid identifier");
    
    // Skip if we're already the selected pane
    if ([identifier isEqualToString:_selectedIdentifier])
        return;
    
    // Make sure the associated class has been instantiated
    id viewPane = [_viewsPanes objectForKey:identifier];
    if (viewPane == nil)
    {
        NSString * className = viewItem[@"ClassName"];
        if (className == nil)
        {
            NSLog(@"Missing ClassName attribute from %@", identifier);
            return;
        }
        Class classObject = objc_getClass([className cStringUsingEncoding:NSASCIIStringEncoding]);
        if (classObject == nil)
        {
            NSLog(@"Cannot find class '%@' in %@", className, identifier);
            return;
        }
        viewPane = [[classObject alloc] initWithObject:_objectData];
        if (viewPane == nil)
            return;
        
        // This is the only safe time to add the pane to the array
        _viewsPanes[identifier] = viewPane;
    }
    
    // If we get this far, OK to select the new item. Otherwise we're staying
    // on the old one.
    NSToolbar * toolbar = [_mainWindow toolbar];
    [toolbar setSelectedItemIdentifier:identifier];
    
    if (_previousView != nil)
        [[_previousView view] removeFromSuperview];
    
    // Compute the new frame window height and width
    NSRect windowFrame = [NSWindow contentRectForFrameRect:[_mainWindow frame] styleMask:[_mainWindow styleMask]];
    
    float newWindowHeight = NSHeight([[viewPane view] frame]) + NSHeight([[toolbar _toolbarView] frame]);
    float newWindowWidth = NSWidth([[viewPane view] frame]);
    
    NSRect newFrameRect = NSMakeRect(NSMinX(windowFrame), NSMaxY(windowFrame) - newWindowHeight, newWindowWidth, newWindowHeight);
    NSRect newWindowFrame = [NSWindow frameRectForContentRect:newFrameRect styleMask:[_mainWindow styleMask]];
    [_mainWindow setFrame:newWindowFrame display:YES animate:[_mainWindow isVisible]];
    
    [[_mainWindow contentView] addSubview:[viewPane view]];
    
    // Remember this pane identifier.
    _selectedIdentifier = identifier;
    _previousView = viewPane;
}

/* Every single toolbar item should be enabled.
 */
-(BOOL)validateToolbarItem:(NSToolbarItem*)toolbarItem
{
    return YES;
}

/* The allowed toolbar items. These are all view items.
 */
-(NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    return _viewsIdentifiers;
}

/* All the selectable toolbar items. This is everything, as usual.
 */
-(NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
    return _viewsIdentifiers;
}

/* The default toolbar items. These are all view items.
 */
-(NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    return _viewsIdentifiers;
}
@end
