//
//  DirectoryCollection.h
//  CIXClient
//
//  Created by Steve Palmer on 28/08/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "DirCategory.h"
#import "DirForum.h"

@interface DirectoryCollection : NSObject {
@private
    NSMutableDictionary * _categories;
    NSMutableDictionary * _forums;
    NSMutableDictionary * _indexList;
    NSUInteger _categoriesToRefesh;
    NSArray * _stopWordList;
    BOOL _indexingEnabled;
}

// Accessors
-(void)setIndexingEnabled:(BOOL)flag;
-(NSArray *)categories;
-(NSArray *)forums;
-(void)sync;
-(void)refresh;
-(void)refreshForum:(NSString *)forumName;
-(DirForum *)forumByName:(NSString *)name;
-(NSArray *)subCategoriesByCategoryName:(NSString *)categoryName;
-(NSArray *)forumsByCategoryName:(NSString *)categoryName;
-(NSArray *)forumsMatchingKeywordsInText:(NSString *)text;
@end
