//
//  FileManagerExtensions.m
//  CIXExtensions
//
//  Created by Steve Palmer on 05/09/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "FileManagerExtensions.h"

@implementation NSFileManager (FileManagerExtensions)


/* Returns whether or not the specified path exists.
 */
-(BOOL)doesFolderExist:(NSString *)path
{
    BOOL isDirectory;
    return ([self fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory);
}

/* Returns whether or not the specified file exists.
 */
-(BOOL)doesFileExist:(NSString *)path
{
    BOOL isDirectory;
    return ([self fileExistsAtPath:path isDirectory:&isDirectory] && !isDirectory);
}

/* Return the full path to the application support folder. If it did not
 * previously exist then it is first created.
 */
-(NSString *)applicationSupportDirectory
{
    NSDictionary * infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString * executableName = infoDictionary[@"CFBundleExecutable"];
    
    NSError * error;
    NSString * result = [self findOrCreateDirectory:NSApplicationSupportDirectory
                                           inDomain:NSUserDomainMask
                                appendPathComponent:executableName
                                              error:&error];
    if (error)
        NSLog(@"Unable to find or create application support directory:\n%@", error);

    return result;
}

/* Locate a predefined search path directory in the given domain and create it if it doesn't exist.
 * If a path component is specified, that is appended to the search path directory before it is
 * used. Sets the optional errorOut variable to the NSError code if there is a failure.
 */
-(NSString *)findOrCreateDirectory:(NSSearchPathDirectory)searchPathDirectory
                          inDomain:(NSSearchPathDomainMask)domainMask
               appendPathComponent:(NSString *)appendComponent
                             error:(NSError **)errorOut
{
    // Search for the path
    NSArray * paths = NSSearchPathForDirectoriesInDomains(searchPathDirectory, domainMask, YES);
    if ([paths count] == 0)
        return nil;
    
    // Normally only need the first path
    NSString *resolvedPath = paths[0];
    if (appendComponent)
        resolvedPath = [resolvedPath stringByAppendingPathComponent:appendComponent];
    
    // Create the path if it doesn't exist
    NSError *error;
    BOOL success = [self createDirectoryAtPath:resolvedPath withIntermediateDirectories:YES attributes:nil error:&error];
    if (!success)
    {
        if (errorOut)
            *errorOut = error;
        return nil;
    }
    
    // If we've made it this far, we have a success
    if (errorOut)
        *errorOut = nil;
    return resolvedPath;
}


/* Iterates all files and folders in the specified path and adds them to the given mappings
 * dictionary. If foldersOnly is YES, only folders are added. If foldersOnly is NO then only
 * files are added.
 */
-(void)loadMapFromPath:(NSString *)path mappings:(NSMutableDictionary *)pathMappings foldersOnly:(BOOL)foldersOnly extensions:(NSArray *)validExtensions
{
    NSArray * arrayOfFiles = [self contentsOfDirectoryAtPath:path error:nil];
    if (arrayOfFiles != nil)
    {
        if (validExtensions)
            arrayOfFiles = [arrayOfFiles pathsMatchingExtensions:validExtensions];
        
        for (NSString * fileName in arrayOfFiles)
        {
            NSString * fullPath = [path stringByAppendingPathComponent:fileName];
            BOOL isDirectory;
            
            if ([self fileExistsAtPath:fullPath isDirectory:&isDirectory] && (isDirectory == foldersOnly))
            {
                if ([fileName isEqualToString:@".DS_Store"])
                    continue;
                
                [pathMappings setValue:fullPath forKey:[fileName stringByDeletingPathExtension]];
            }
        }
    }
}
@end
