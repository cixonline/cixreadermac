//
//  LogFile.m
//  CIXClient
//
//  Created by Steve Palmer on 10/07/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "LogFile.h"
#import "StringExtensions.h"

// Later consider making this a property...
int const ArchiveMaximum = 9;

@interface LogFile (Private)
    -(void)archiveOldLogs;
@end

@implementation LogFile

/** Returns the shared instance of the log file
 
 To serialise access to the log file, a single instance is provided for all
 callers to write to the log file.
 
 @return A LogFile object providing access to the LogFile methods.
 */
+(LogFile *)logFile
{
    static LogFile * myLogFile = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        myLogFile = [[self alloc] init];
    });
    return myLogFile;
}

/** Close the log file.
 
 This method should be called before the application shuts down. It ensures
 that the log file is flushed and correctly closed. After this method has returned,
 the log file can still be written to as it will automatically be re-opened on the
 next call to writeLine:
 */
-(void)close
{
    if (_file != nil)
    {
        [_file closeFile];
        _file = nil;
    }
}

/** Write a formatted string to the log file.
 
 The format string must be specified in NSString stringWithFormat: format and all
 optional arguments must be specified if they are referenced in the format string.
 
 The log file format consists of lines as follows:
 
     10/10/2014 11:07:15 : string
 
 where the date and time are automatically written by the writeLine: method and set
 to the date and time at which the method was called. The string is the result of
 combining the format string and its optional arguments.
 
 If this is the first call to writeLine: in the session then the log file will be
 created or opened as part of the call and if archiving is enabled, the old log
 files will be automatically archived. Thus the first call will take longer than
 subsequent calls. No validation is done on the path so if an invalid path has been
 passed then no log file will be created and writeLine will return without writing
 anything. The enabled property will also be automatically set to NO to ensure that
 subsequent calls to writeLine do not attempt to repeatedly create an invalid file.
 
 Note that you should set the enabled property to YES before calling writeLine: or
 nothing will happen. Also if you require cumulative logging or archiving then those
 should be specified via the corresponding properties before the FIRST call to
 writeLine as they will be ignored afterwards.
 
 @param formatString The string to be written to the log file
 @param ... Any optional arguments required by the formatString
 */
-(void)writeLine:(NSString *)formatString, ...
{
    @synchronized(self) {
        if (self.enabled)
        {
            if (_file == nil)
            {
                NSFileManager * fileManager = [NSFileManager defaultManager];
                
                if (!self.cumulative && self.archive)
                    [self archiveOldLogs];

                _file = [NSFileHandle fileHandleForWritingAtPath:self.path];
                if (_file == nil)
                {
                    NSString * folderForFile = [[self path] stringByDeletingLastPathComponent];
                    BOOL isDirectory;

                    // Make sure the log file folder exists
                    if (![fileManager fileExistsAtPath:folderForFile isDirectory:&isDirectory])
                    {
                        [fileManager createDirectoryAtPath:folderForFile withIntermediateDirectories:YES attributes:nil error:nil];
                    }
                    
                    [fileManager createFileAtPath:[self path] contents:nil attributes:nil];
                    _file = [NSFileHandle fileHandleForWritingAtPath:self.path];
                }
                if (_file == nil)
                {
                    // No luck, so disable logging
                    self.enabled = false;
                    return;
                }

                if (self.cumulative)
                    [_file seekToEndOfFile];
                else
                    [_file truncateFileAtOffset:0L];
            }
            
            if (_file != nil)
            {
                va_list args;
                va_start(args, formatString);
                
                NSDateFormatter * dateFormat = [[NSDateFormatter alloc] init];
                [dateFormat setDateFormat:@"dd/MM/yyyy"];
                
                NSDateFormatter * timeFormat = [[NSDateFormatter alloc] init];
                [timeFormat setDateFormat:@"HH:mm:ss"];
                
                NSDate * now = [[NSDate alloc] init];
                
                NSString * theDate = [dateFormat stringFromDate:now];
                NSString * theTime = [timeFormat stringFromDate:now];
                
                NSString * stringToWrite = [[NSString alloc] initWithFormat:formatString arguments:args];
                NSString * completeLine = [NSString stringWithFormat:@"%@ %@ : %@\r\n", theDate, theTime, stringToWrite];
                
                [_file writeData:[completeLine dataUsingEncoding:NSUTF8StringEncoding]];
            }
        }
    }
}

/* Archive old log files.
 */
-(void)archiveOldLogs
{
    for (int extMax = ArchiveMaximum - 1; extMax >= 0; --extMax)
    {
        NSString * archiveNew = [self.path stringByChangingPathExtension:[NSString stringWithFormat:@"%.3i", extMax + 1]];
        NSString * archiveCurrent = (extMax > 0) ? [self.path stringByChangingPathExtension:[NSString stringWithFormat:@"%.3i", extMax]] : self.path;
        
        [[NSFileManager defaultManager] moveItemAtPath:archiveCurrent toPath:archiveNew error:nil];
    }
}

@end
