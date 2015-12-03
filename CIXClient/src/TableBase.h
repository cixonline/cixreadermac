//
//  TableBase.h
//  CIXClient
//
//  Created by Steve Palmer on 12/10/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

typedef long long int ID_type;

@interface TableBase : NSObject

// Accessors
+(NSString *)tableName;
+(NSArray *)allRows;
+(NSArray *)allRowsWithQuery:(NSString *)queryString;
+(NSInteger)countRowsWithQuery:(NSString *)queryString;
+(void)create;
+(void)upgrade;
-(void)save;
-(void)saveNew;
-(void)delete;
@end