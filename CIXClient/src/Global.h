//
//  Global.h
//  CIXClient
//
//  Created by Steve Palmer on 12/11/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "TableBase.h"

@interface Global : TableBase

@property int version;
@property NSDate * lastSyncDate;

// Accessors
-(int)databaseVersion;
-(void)setDatabaseVersion:(int)value;
-(NSDate *)databaseLastSyncDate;
-(void)setDatabaseLastSyncDate:(NSDate *)date;
@end
