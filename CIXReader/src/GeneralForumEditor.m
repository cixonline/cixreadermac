//
//  GeneralForumEditor.m
//  CIXReader
//
//  Created by Steve Palmer on 06/10/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "CIX.h"
#import "GeneralForumEditor.h"
#import "StringExtensions.h"

@implementation GeneralForumEditor

-(id)initWithObject:(id)forum
{
    if ((self = [super initWithNibName:@"GeneralForumEditor" bundle:nil]) != nil)
        _forum = forum;
    return self;
}

/* Populate the fields in the window.
 */
-(void)awakeFromNib
{
    if (!_didInitialise)
    {
        forumName.stringValue = _forum.name;
        forumTitle.stringValue = _forum.title;
        forumDescription.string = _forum.desc;
        
        // Forum type. Valid characters will be 'o', 'c' and 'p'
        // which should map to the tag value on each popup.
        char forumTypeChar = 'o';
        if (![_forum.type isBlank])
            forumTypeChar = [[_forum.type lowercaseString] characterAtIndex:0];
        [forumType selectItemWithTag:forumTypeChar];
        [self handleForumTypeChange:nil];

        // Categories.
        NSArray * categories = [[CIX.directoryCollection categories] sortedArrayUsingSelector:@selector(localizedCompare:)];
        for (NSString * categoryName in categories)
            [forumCategory addItemWithTitle:categoryName];

        // Initially select the first category to which the forum belongs
        NSString * category = _forum.cat;
        [forumCategory selectItemWithTitle:category];
        
        // Fill out all the sub-categories for this category
        [self fillSubcategoryList:category];
        [forumSubCategory selectItemWithTitle:_forum.sub];
        
        // Get notified when the window is closed via the Close button
        NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:nil];
        _didInitialise = YES;
    }
}

-(void)windowWillClose:(NSNotification *)notification
{
    MultiViewController * parent = [[NSApp modalWindow] windowController];
    [parent closeAllViews:NO];
}

/* Respond to changes to the forum type to disable category and
 * subcategory for private forums since those are always unlisted.
 */
-(IBAction)handleForumTypeChange:(id)sender
{
    char forumTypeChar = [forumType selectedTag];
    [forumCategory setEnabled:(forumTypeChar != 'p')];
    [forumSubCategory setEnabled:(forumTypeChar != 'p')];
}

/* Respond to changes to the category name to reset the list of subcategories
 * to those that are members of the selected category.
 */
-(IBAction)handleCategoryChange:(id)sender
{
    NSString * selectedCategory = [[forumCategory selectedItem] title];
    [self fillSubcategoryList:selectedCategory];
    [forumSubCategory selectItemAtIndex:0];
}

/* Fill out the sorted sub-category list.
 */
-(void)fillSubcategoryList:(NSString *)category
{
    [forumSubCategory removeAllItems];
    
    NSArray * subCategories = [CIX.directoryCollection subCategoriesByCategoryName:category];
    NSMutableArray * sortedSubCategories = [NSMutableArray array];

    for (DirCategory * subCategory in subCategories)
        [sortedSubCategories addObject:subCategory.sub];
    
    [sortedSubCategories sortedArrayUsingSelector:@selector(localizedCompare:)];
    
    for (NSString * subCategoryName in sortedSubCategories)
        [forumSubCategory addItemWithTitle:subCategoryName];
}

/* Close the view and save any changes.
 */
-(BOOL)closeView:(BOOL)response
{
    if (response)
    {
        _forum.name = forumName.stringValue;
        _forum.title = forumTitle.stringValue;
        _forum.desc = forumDescription.string;
        
        _forum.cat = [[forumCategory selectedItem] title];
        _forum.sub = [[forumSubCategory selectedItem] title];
        
        _forum.type = [NSString stringWithFormat:@"%c", (char)[forumType selectedTag]];
        
        [_forum update];
    }

    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:NSWindowWillCloseNotification object:nil];
    
    return YES;
}

/* Save changes back to the _forum object and then commit them.
 */
-(IBAction)handleSaveButton:(id)sender
{
    MultiViewController * parent = [[NSApp modalWindow] windowController];
    [parent closeAllViews:YES];
}

/* Exit without saving any changes.
 */
-(IBAction)handleCancelButton:(id)sender
{
    MultiViewController * parent = [[NSApp modalWindow] windowController];
    [parent closeAllViews:NO];
}
@end
