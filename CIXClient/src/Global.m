//
//  Global.m
//  CIXClient
//
//  Created by Steve Palmer on 12/11/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "Global.h"
#import "CIX.h"
#import "DateExtensions.h"

@implementation Global

/* This class has no identity column.
 */
+(NSString *)identityColumn
{
    return nil;
}

/** Return the current database version

 @return The database version number.
 */
-(int)databaseVersion
{
    NSArray * results = [Global allRows];
    if (results != nil && results.count == 1)
    {
        Global * row = results[0];
        self.version = row.version;
        self.lastSyncDate = row.lastSyncDate;
    }
    else
    {
        self.version = LatestDatabaseVersion;
        self.lastSyncDate = [NSDate defaultDate];
        [self saveNew];
    }
    return self.version;
}

/** Set the new database version
 
 @param value The new database version number
 */
-(void)setDatabaseVersion:(int)value
{
    self.version = value;
    [self save];
}

/* Return the date and time of the last sync
 */
-(NSDate *)databaseLastSyncDate
{
    return self.lastSyncDate;
}

/* Set the date and time of the last sync.
 */
-(void)setDatabaseLastSyncDate:(NSDate *)date
{
    self.lastSyncDate = date;
    [self save];
}
@end
