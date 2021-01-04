//
//  CategoryFolder.m
//  CIXReader
//
//  Created by Steve Palmer on 28/08/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "CategoryFolder.h"
#import "CIX.h"

const static NSDictionary * categoryList;

@implementation CategoryFolder

/* Initialise a category folder with the specified name and icon.
 */
-(id)initWithName:(NSString *)name
{
    if ((self = [super init]) != nil)
    {
        if (categoryList == nil)
            categoryList = @{@"Arts"                 : @"ArtsCategory.tiff",
                             @"Business"             : @"BusinessCategory.tiff",
                             @"CIX"                  : @"CIXCategory.tiff",
                             @"Computers"            : @"ComputersCategory.tiff",
                             @"Games"                : @"GamesCategory.tiff",
                             @"Health"               : @"HealthCategory.tiff",
                             @"Home & Family"        : @"HomeCategory.tiff",
                             @"Kids and Teens"       : @"KidsCategory.tiff",
                             @"Money"                : @"MoneyCategory.tiff",
                             @"News"                 : @"NewsCategory.tiff",
                             @"Reference"            : @"ReferenceCategory.tiff",
                             @"Science & Technology" : @"ScienceCategory.tiff",
                             @"Shopping"             : @"ShoppingCategory.tiff",
                             @"Society"              : @"SocietyCategory.tiff",
                             @"Sports"               : @"SportsCategory.tiff",
                             @"Travel & Transport"   : @"TravelCategory.tiff"};
        [self setName:name];
    }
    return self;
}

/* Return the icon for the specified category.
 */
+(NSImage *)iconForCategory:(NSString *)categoryName
{
    NSImage * image = [NSImage imageNamed:[categoryList valueForKey:categoryName]];
    if (image == nil)
        image = [NSImage imageNamed:@"CIXCategory.tiff"];
    return image;
}

/* Return the category icon
 */
-(NSImage *)icon
{
    if (_image == nil)
        _image = [CategoryFolder iconForCategory:self.name];
    return _image;
}

/* Return the localised name of the All Categories folder.
 */
+(NSString *)allCategoriesName
{
    return NSLocalizedString(@"All Categories", nil);
}

/* Return the type of view for this folder.
 */
-(AppView)viewForFolder
{
    return AppViewDirectory;
}

/* Refresh the entire directory.
 */
-(BOOL)refresh
{
    [CIX.directoryCollection refresh];
    return YES;
}

/* Allow searches scoped to this folder.
 */
-(BOOL)allowsScopedSearch
{
    return YES;
}

/* Return the list of forums for the current category. If folder is nil or the category
 * name is "All", all forums are returned.
 */
-(NSArray *)items
{
    if ([self.name isEqualToString:[CategoryFolder allCategoriesName]])
        return [CIX.directoryCollection forums];
    
    return [CIX.directoryCollection forumsByCategoryName:self.name];
}
@end
