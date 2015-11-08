//
//  FileManagerExtensions.h
//  CIXExtensions
//
//  Created by Steve Palmer on 05/09/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

@interface NSFileManager (FileManagerExtensions)
    -(BOOL)doesFileExist:(NSString *)path;
    -(BOOL)doesFolderExist:(NSString *)path;
    -(NSString *)applicationSupportDirectory;
    -(void)loadMapFromPath:(NSString *)path mappings:(NSMutableDictionary *)pathMappings foldersOnly:(BOOL)foldersOnly extensions:(NSArray *)validExtensions;
@end
