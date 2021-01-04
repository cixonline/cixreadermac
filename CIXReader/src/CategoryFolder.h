//
//  CategoryFolder.h
//  CIXReader
//
//  Created by Steve Palmer on 28/08/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "FolderBase.h"

@interface CategoryFolder : FolderBase<FolderProtocol> {
    NSImage * _image;
}

// Accessors
-(id)initWithName:(NSString *)name;
+(NSImage *)iconForCategory:(NSString *)categoryName;
+(NSString *)allCategoriesName;
@end
