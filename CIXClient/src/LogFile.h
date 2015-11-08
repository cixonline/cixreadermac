//
//  LogFile.h
//  CIXClient
//
//  Created by Steve Palmer on 10/07/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

/** Provides access to a centralised log file

 The LogFile class provides a way to log to a log file complete with date and time
 stamping, serialised access from multiple threads and archiving.
 
 The easiest way to begin logging is simply:
 
     LogFile * logFile = LogFile.logFile;
 
     [logFile setPath:@"/Users/steve/Documents/mylog.log"];
     [logFile setEnabled:YES];
     [logFile writeLine:@"Hello with %d", 12];
 
 In addition, you can control whether log files are archived which ensures that older
 log files are preserved up to a maximum of 9. Archiving should be enabled BEFORE the
 first call to writeLine or otherwise the previous log file will be overwritten.
 
 By default, each new log file overwrites the previous one unless the cumulative
 property is set to YES before the first call to writeLine.
 */
@interface LogFile : NSObject {
@private
    NSFileHandle * _file;
}

/** Set or get the file name of the log file.
 
 The LogFile will automatically create the destination folder and any
 intermediate folders if they do not exist.
 
 @return An NSString specifying the log file name and path.
 */
@property NSString * path;

/** Set or get a flag which controls whether logging is enabled.

 By default, the log file is disabled so calls to writeLine: have no effect
 until the enabled property is set to YES and a valid log file path has been
 specified.
 
 @return A boolean set to YES if logging is enabled, NO otherwise.
 */
@property BOOL enabled;

/** Set or get a flag which controls whether logging is cumulative.
 
 Cumulative logging appends new log file entries to the end of the old log
 file if one exists. By default when the log file is first opened on the
 first call to writeLine: the existing contents are deleted. So this flag
 should be set before the first writeLine: to ensure that prior contents are
 preserved.
 
 @return A boolean set to YES if logging is cumulative, NO otherwise.
 */
@property BOOL cumulative;

/** Set or get a flag which controls whether log files are archived.
 
 By default, old log files are not archived. Enabling archiving ensures that
 old log files are preserved before the new log file is created. Up to a maximum
 of 9 log files are preserved and the 10th oldest log file is always deleted.
 
 The format for archived files is to change the log file path extension to
 a three digit numerical value from 001 to 009 where 001 is the most recent
 archived log file and 009 is the oldest. When a new archive is created, 001 is
 renamed to 002 and 002 to 003, and 009 is overwritten by 008.
 
 NOTE: You cannot archive if cumulative is set to YES. Cumulative logging
 overrides archiving but will not delete any existing archive files.
 
 @return A boolean set to YES if log file archiving is enabled, NO otherwise.
 */
@property BOOL archive;

// Accessors
+(LogFile *)logFile;
-(void)close;
-(void)writeLine:(NSString *)formatString, ...;

@end
