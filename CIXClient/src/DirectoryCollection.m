//
//  DirectoryCollection.m
//  CIXClient
//
//  Created by Steve Palmer on 28/08/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "CIX.h"
#import "FMDatabase.h"
#import "DirForum_Private.h"
#import "StringExtensions.h"
#import "CategoryResultSet.h"
#import "ForumDetailsGet.h"
#import "DirListings.h"

@implementation DirectoryCollection

/* Synchronise any offline changes to forums that are moderated by the
 * authenticated user.
 */
-(void)sync
{
    if (CIX.online)
    {
        @try {
            for (DirForum * forum in self.forums)
            {
                if ([forum hasPending])
                    [forum sync];
            }
        }
        @catch (NSException *exception) {
            [CIX reportServerExceptions:__PRETTY_FUNCTION__ exception:exception];
        }
    }
}

/* Toggle indexing of the directory content.
 */
-(void)setIndexingEnabled:(BOOL)flag
{
    if (flag != _indexingEnabled)
    {
        _indexingEnabled = flag;
        if (_indexingEnabled)
            [self index];
    }
}

/* Return all the top-level categories, loading from the database if
 * required.
 */
-(NSArray *)categories
{
    if (_categories == nil)
    {
        NSArray * results = [DirCategory allRows];

        _categories = [[NSMutableDictionary alloc] init];
        for (DirCategory * category in results)
        {
            NSMutableArray * subcategories = [_categories objectForKey:category.name];
            if (subcategories == nil)
            {
                subcategories = [NSMutableArray array];
                _categories[category.name] = subcategories;
            }
            [subcategories addObject:category];
        }
    }
    return _categories.allKeys;
}

/* Return all forums, loading from the database if required.
 */
-(NSArray *)forums
{
    if (_forums == nil)
    {
        // Ensure categories have been loaded!
        [self categories];
        
        NSArray * results = [DirForum allRows];

        _forums = [[NSMutableDictionary alloc] init];
        for (DirForum * forum in results)
            _forums[@(forum.ID)] = forum;
        
        [self index];
    }
    return [_forums allValues];
}

/* Return the DirCategory matching the specified name and subcategory.
 */
-(DirCategory *)categoryByName:(NSString *)name subCategory:(NSString *)subCategory
{
    NSArray * subcategories = [self subCategoriesByCategoryName:name];
    for (DirCategory * category in subcategories)
    {
        if ([category.sub isEqualToString:subCategory])
            return category;
    }
    return nil;
}

/* Return all forums belonging to the specified category
 */
-(NSArray *)forumsByCategoryName:(NSString *)categoryName
{
    NSMutableArray * forums = [NSMutableArray array];
    for (DirForum * forum in [self forums])
    {
        if ([forum.cat isEqualToString:categoryName])
            [forums addObject:forum];
    }
    return forums;
}

/* Return all subcategories belonging to the specified category
 */
-(NSArray *)subCategoriesByCategoryName:(NSString *)categoryName
{
    return [_categories objectForKey:categoryName];
}

/* Return the DirForums corresponding to the given name.
 */
-(DirForum *)forumByName:(NSString *)name
{
    for (DirForum * forum in [self forums])
    {
        if ([forum.name isEqualToString:name])
            return forum;
    }
    return nil;
}

/* Index all the forum descriptions and generate a dictionary of keywords with
 * an array of forums matching those keywords.
 */
-(void)index
{
    if (_indexingEnabled)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self->_indexList = [NSMutableDictionary dictionary];
            
            // Make a copy of the array in case it changes beneath us
            NSArray * forumsCopy = [[self forums] copy];
            for (DirForum * forum in forumsCopy)
                if (![forum.desc isBlank])
                {
                    NSArray * filteredWords = [self keywordsFromText:forum.desc];
                    
                    for (NSString * word in filteredWords)
                        if (![word isBlank])
                        {
                            NSMutableArray * forumList = self->_indexList[word];
                            if (forumList == nil)
                            {
                                forumList = [NSMutableArray array];
                                self->_indexList[word] = forumList;
                            }
                            
                            if (![forumList containsObject:forum])
                                [forumList addObject:forum.name];
                        }
                }
        });
}

/** Return an ordered list of forum names matching the keywords in the given text.
 
 @param text The text to parse for keywords
 @return An NSArray of NSString objects representing the forum names
 */
-(NSArray *)forumsMatchingKeywordsInText:(NSString *)text
{
    NSMutableArray * forums = [NSMutableArray array];
    
    NSArray * filteredWords = [self keywordsFromText:text];
    for (NSString * word in filteredWords)
        if (![word isBlank])
        {
            if (_indexList[word] != nil)
                [forums addObjectsFromArray:_indexList[word]];
        }
    
    // Now forums will contain duplicates so sort them by the number of occurrences
    // of each forum in the list, common first.
    NSCountedSet *countedSet = [[NSCountedSet alloc] initWithArray:forums];

    return [[countedSet allObjects] sortedArrayUsingComparator:^NSComparisonResult(NSString * obj1, NSString * obj2) {
        NSUInteger obj1Count = [countedSet countForObject:obj1];
        NSUInteger obj2Count = [countedSet countForObject:obj2];
        
        if (obj1Count > obj2Count)
            return NSOrderedAscending;
        if (obj1Count < obj2Count)
            return NSOrderedDescending;
        return NSOrderedSame;
    }];
}

/* Return a list of keywords from the given text
 */
-(NSArray *)keywordsFromText:(NSString *)text
{
    NSPredicate *intersectPredicate = [NSPredicate predicateWithFormat:@"NOT (SELF IN %@)", [self stopWordList]];
    
    NSMutableCharacterSet * separators = [NSMutableCharacterSet characterSetWithCharactersInString:@",;.:() \n\t\r"];
    
    NSArray * words = [text componentsSeparatedByCharactersInSet:separators];
    return [words filteredArrayUsingPredicate:intersectPredicate];
}

/* Return the stop word list for the current system language.
 */
-(NSArray *)stopWordList
{
    if (_stopWordList == nil)
    {
        NSBundle * frameworkBundle = [NSBundle bundleForClass:[DirForum class]];
        NSString * stopwordsFile = [frameworkBundle pathForResource:@"Stopwords" ofType:@"txt"];
        
        NSError * error = nil;
        
        NSString * fileContents = [NSString stringWithContentsOfFile:stopwordsFile encoding:NSUTF8StringEncoding error:&error];
        _stopWordList = [fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    }
    return _stopWordList;
}

/** Refresh the details for a single forum.
 
 This method calls the API to retrieve the full details of a forum given its name. The call
 is made asynchronously so the caller should subscribe to the MAForumChanged event to be notified
 of completion. The notification object will contain a Response object which indicates the success
 or failure of the refresh. If the error code is CCResponse_NoError then the response object will
 contain the completed DirForum object for the forum. If the forum does not exist then the
 error code will be CCResponse_NoSuchForum.
 
 @param forumName The name of the forum to refresh
 */
-(void)refreshForum:(NSString *)forumName
{
    if (!CIX.online)
    {
        NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:MAForumChanged object:[Response responseWithObject:nil andError:CCResponse_Offline]];
        return;
    }

    NSString * encodedForumName = [forumName stringByReplacingOccurrencesOfString:@"." withString:@"~"];
    NSString * url = [NSString stringWithFormat:@"forums/%@/details", encodedForumName];
    NSURLRequest * request = [APIRequest get:url];
    if (request != nil)
    {
        [LogFile.logFile writeLine:@"Updating directory for %@", forumName];

        NSURLSession * session = [NSURLSession sharedSession];
        NSURLSessionDataTask * task = [session dataTaskWithRequest:request
                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                       {
                                           Response * resp = [[Response alloc] initWithObject:nil];
                                           if (error != nil)
                                           {
                                               [CIX reportServerErrors:__PRETTY_FUNCTION__ error:error];
                                               resp.errorCode = CCResponse_ServerError;
                                           }
                                           else
                                           {
                                               JSONModelError * jsonError = nil;
                                               
                                               J_ForumDetailsGet * details = [[J_ForumDetailsGet alloc] initWithData:data error:&jsonError];
                                               if (jsonError != nil)
                                                   resp.errorCode = CCResponse_NoSuchForum;
                                               else
                                               {
                                                   DirForum * forum = [self forumByName:details.Name];
                                                   BOOL isNewForum = NO;
                                                   if (forum == nil)
                                                   {
                                                       forum = [[DirForum alloc] init];
                                                       isNewForum = YES;
                                                   }

                                                   forum.name = details.Name;
                                                   forum.title = details.Title;
                                                   forum.desc = details.Description;
                                                   forum.type = details.Type;
                                                   forum.recent = details.Recent;
                                                   forum.cat = details.Category;
                                                   forum.sub = details.SubCategory;
                                                   forum.detailsPending = NO;
                                                   [forum save];
                                                   
                                                   resp.object = forum;
                                                   
                                                   if (isNewForum)
                                                       self->_forums[@(forum.ID)] = forum;

                                                   [LogFile.logFile writeLine:@"Directory for %@ updated", forum.name];
                                               }
                                           }
                                           
                                           // Notify interested parties that the directory has changed
                                           dispatch_async(dispatch_get_main_queue(),^{
                                               NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
                                               [nc postNotificationName:MAForumChanged object:resp];
                                           });
                                       }];
        [task resume];
    }
}

/* Refresh the directory, replacing the existing directory in the database.
 */
-(void)refresh
{
    NSURLRequest * request = [APIRequest get:@"directory/categories"];
    if (request != nil && _categoriesToRefesh == 0)
    {
        // Callback to notify that the directory refresh has commenced.
        dispatch_async(dispatch_get_main_queue(),^{
            NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
            [nc postNotificationName:MADirectoryRefreshStarted object:self];
        });

        NSURLSession * session = [NSURLSession sharedSession];
        NSURLSessionDataTask * task = [session dataTaskWithRequest:request
                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                       {
                                           if (error != nil)
                                               [CIX reportServerErrors:__PRETTY_FUNCTION__ error:error];
                                           else
                                           {
                                               JSONModelError * jsonError = nil;
                                               int countOfNewCategories = 0;
                                               
                                               J_CategoryResultSet * categories = [[J_CategoryResultSet alloc] initWithData:data error:&jsonError];
                                               if (jsonError == nil)
                                               {
                                                   @synchronized(CIX.DBLock) {
                                                       [CIX.DB beginTransaction];
                                                       
                                                       for (J_Category * category in categories.Categories)
                                                       {
                                                           DirCategory * newCategory = [self categoryByName:category.Name subCategory:category.Sub];
                                                           if (newCategory == nil)
                                                           {
                                                               newCategory = [[DirCategory alloc] init];
                                                               newCategory.ID = 0;
                                                               newCategory.name = category.Name;
                                                               newCategory.sub = category.Sub;
                                                               
                                                               NSMutableArray * subcategories = [self->_categories objectForKey:newCategory.name];
                                                               if (subcategories == nil)
                                                               {
                                                                   subcategories = [NSMutableArray array];
                                                                   self->_categories[newCategory.name] = subcategories;
                                                               }
                                                               [subcategories addObject:newCategory];
                                                               
                                                               [newCategory save];
                                                               ++countOfNewCategories;
                                                           }
                                                       }
                                                       [CIX.DB commit];
                                                   }
                                                   
                                                   if (countOfNewCategories > 0)
                                                   {
                                                       [LogFile.logFile writeLine:@"Directory refreshed with %d new categories", countOfNewCategories];
                                                   
                                                       // Notify interested parties that the directory has changed
                                                       dispatch_async(dispatch_get_main_queue(),^{
                                                           NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
                                                           [nc postNotificationName:MADirectoryChanged object:nil];
                                                       });
                                                   }
                                                   
                                                   // Now we need to pull down all the forums in each category
                                                   [self refreshCategories];
                                               }
                                           }
                                       }];
        [task resume];
    }
}

/* For each category, refresh the forums listed in them
 */
-(void)refreshCategories
{
    _categoriesToRefesh = self.categories.count;
    for (NSString * categoryName in self.categories)
    {
        NSString * safeCategoryName = [categoryName stringByReplacingOccurrencesOfString:@"&" withString:@"+and+"];
        safeCategoryName = [safeCategoryName stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        
        NSString * url = [NSString stringWithFormat:@"directory/%@/forums", safeCategoryName];
        NSURLRequest * request = [APIRequest get:url];

        // Spin up one task per category. Is this too much though?
        NSURLSession * session = [NSURLSession sharedSession];
        NSURLSessionDataTask * task = [session dataTaskWithRequest:request
                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                       {
                                           if (self->_categoriesToRefesh > 0)
                                               self->_categoriesToRefesh -= 1;
                                           if (error != nil)
                                               [CIX reportServerErrors:__PRETTY_FUNCTION__ error:error];
                                           else
                                           {
                                               JSONModelError * jsonError = nil;
                                               J_DirListings * categories = [[J_DirListings alloc] initWithData:data error:&jsonError];
                                               if (jsonError == nil)
                                               {
                                                   int countOfNewForums = 0;
                                                   
                                                   @synchronized(CIX.DBLock) {
                                                       [CIX.DB beginTransaction];
                                                       for (J_Listing * result in categories.Forums)
                                                       {
                                                           DirForum * forum = [self forumByName:result.Forum];
                                                           if (forum == nil)
                                                           {
                                                               forum = [[DirForum alloc] init];
                                                               forum.name = result.Forum;
                                                           }
                                                           forum.recent = result.Recent;
                                                           forum.title = result.Title;
                                                           forum.type = result.Type;
                                                           forum.cat = result.Cat;
                                                           forum.sub = result.Sub;
                                                           forum.detailsPending = NO;
                                                           [forum save];

                                                           self->_forums[@(forum.ID)] = forum;
                                                           ++countOfNewForums;
                                                       }
                                                       [CIX.DB commit];
                                                   }
                                                   
                                                   if (countOfNewForums > 0)
                                                   {
                                                       [LogFile.logFile writeLine:@"%d forums in category %@", countOfNewForums, categoryName];

                                                       dispatch_async(dispatch_get_main_queue(),^{
                                                           NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
                                                           [nc postNotificationName:MADirectoryChanged object:categoryName];
                                                       });
                                                   }
                                               }
                                           }

                                           // On the last category, post that the refresh completed
                                           if (self->_categoriesToRefesh == 0)
                                           {
                                               dispatch_async(dispatch_get_main_queue(),^{
                                                   NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
                                                   [nc postNotificationName:MADirectoryRefreshCompleted object:nil];
                                               });
                                               
                                               // Rebuild the index
                                               [self index];
                                           }
                                       }];
        [task resume];
    }
}
@end
