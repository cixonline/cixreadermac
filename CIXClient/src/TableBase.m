//
//  TableBase.m
//  CIXClient
//
//  Created by Steve Palmer on 12/10/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "CIX.h"
#import "TableBase.h"
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "StringExtensions.h"
#import "ImageExtensions.h"
#import "objc/runtime.h"

@implementation TableBase

/** Return the SQL table name for this class
 
 By default, the table name is the class name. Subclasses should override
 this method to return an alternate name if so desired.
 
 @return The table name required for this class.
 */
+(NSString *)tableName
{
    return NSStringFromClass(self.class);
}

/** Return the property name of the identity column
 
 By default, all classes have an identity column and the default property
 for the identity column is the integer ID property. However subclasses can
 override this to specify an alternative identity column if so desired.
 
 @return The property name of the identity column.
 */
+(NSString *)identityColumn
{
    return @"ID";
}

/** Return whether this table should be indexed
 
 By default no index is created. To force an index to be created using the
 identity column, override this method to return YES.
 
 @return YES to create an index on this table, NO otherwise.
 */
+(BOOL)requiresIndex
{
    return NO;
}

/** Return an NSArray of all objects from the database
 
 @return An NSArray of objects representing the table type.
 */
+(NSArray *)allRows
{
    return [self allRowsWithQuery:@""];
}

/** Return the number of rows matching the specified query
 
 @param queryString The SQL condition string to be used to filter the query
 @return An integer count of rows matching the query
 */
+(NSInteger)countRowsWithQuery:(NSString *)queryString
{
    NSInteger count = 0;
    @synchronized(CIX.DBLock) {
        count = [CIX.DB intForQuery:[NSString stringWithFormat:@"select count(*) from %@%@", [self.class tableName], queryString]];
    }
    return count;
}

/** Return an NSArray of all objects from the database filtered by a SQL query

 @param queryString The SQL condition string to be used to filter the query
 @return An NSArray of objects of the table type.
 */
+(NSArray *)allRowsWithQuery:(NSString *)queryString
{
    NSMutableArray * rows = [NSMutableArray array];
    @synchronized(CIX.DBLock) {
        FMResultSet * results = [CIX.DB executeQuery:[NSString stringWithFormat:@"select * from %@%@", [self.class tableName], queryString]];

        NSDictionary * properties = [TableBase classPropsFor:self.class];
        
        while (results != nil && [results next])
        {
            id item = [self.class new];
            
            for (NSString * name in properties.allKeys)
            {
                NSString * type = [properties valueForKey:name];
                if ([type isEqualToString:@"NSString"])
                {
                    [item setValue:[results stringForColumn:name] forKey:name];
                    continue;
                }
                if ([type isEqualToString:@"i"] || [type isEqualToString:@"B"] || [type isEqualToString:@"c"])
                {
                    [item setValue:[NSNumber numberWithInt:[results intForColumn:name]] forKey:name];
                    continue;
                }
                if ([type isEqualToString:@"NSDate"])
                {
                    [item setValue:[results dateForColumn:name] forKey:name];
                    continue;
                }
                if ([type isEqualToString:@"q"])
                {
                    [item setValue:[NSNumber numberWithLongLong:[results longLongIntForColumn:name]] forKey:name];
                    continue;
                }
                if ([type isEqualToString:@"NSImage"])
                {
                    [item setValue:[[ImageClass alloc] initWithData:[results dataForColumn:name]] forKey:name];
                    continue;
                }
                [NSException raise:@"Unsupported property type" format:@"Type %@ cannot be mapped to a SQLite type", type];
            }
            
            [rows addObject:item];
        }
        [results close];
    }
    return rows;
}

/** Create the SQL table for the class

 Create the SQL table for this class by dynamically constructing the SQL
 statement from the class properties. For this to work, the class properties
 must be limited to the following types:
 
 NSString
 NSDate
 int
 BOOL
 longlong
 
 Any unsupported type will result in an exception being thrown.
 
 The identity column is automatically declared as the primary key and will
 auto-increment if it is a numerical type.
 */
+(void)create
{
    NSMutableString * sqlCreate = [[NSMutableString alloc] init];
    
    [sqlCreate appendString:@"create table if not exists "];
    [sqlCreate appendString:[self tableName]];
    [sqlCreate appendString:@" ("];
    
    NSDictionary * properties = [TableBase classPropsFor:self.class];
    NSDictionary * mapTypeToSQLType = [self typeToSQLTypeMap];
    NSString * separator = @"";

    for (NSString * name in properties.allKeys)
    {
        NSString * type = [properties valueForKey:name];
        NSString * sqlType = [mapTypeToSQLType valueForKey:type];
        
        if (sqlType == nil)
            [NSException raise:@"Unsupported property type" format:@"Type %@ cannot be mapped to a SQLite type", type];
        
        [sqlCreate appendFormat:@"%@%@ %@", separator, name, sqlType];
        if ([name isEqualToString:[self identityColumn]])
        {
            NSString * autoIncr = [sqlType isEqualToString:@"INTEGER"] ? @"autoincrement" : @"";
            [sqlCreate appendFormat:@" primary key %@ not null", autoIncr];
        }
        
        separator = @",";
    }
    
    [sqlCreate appendString:@")"];

    @synchronized(CIX.DBLock) {
        [[CIX DB] executeUpdate:sqlCreate];
    }

    // Create the index only if the table declares one.
    if (self.requiresIndex)
    {
        NSString * sqlIndex = [NSString stringWithFormat:@"create index if not exists %@_%@ on %@(%@)",
                               [self tableName],
                               [self identityColumn],
                               [self tableName],
                               [self identityColumn]];
        [[CIX DB] executeUpdate:sqlIndex];
    }
}

/** Upgrade the table to match the current schema

 Currently this just adds missing columns. Later we can add logic to drop
 columns to clean up behind ourselves.
 */
+(void)upgrade
{
    FMResultSet * schema = [[CIX DB] getTableSchema:[self tableName]];

    NSMutableArray * allColumns = [NSMutableArray array];
    
    while (schema != nil && [schema next])
    {
        NSString * columnName = [schema stringForColumnIndex:1];
        [allColumns addObject:columnName];
    }
    [schema close];
    
    NSDictionary * properties = [TableBase classPropsFor:self.class];
    NSDictionary * mapTypeToSQLType = [self typeToSQLTypeMap];

    for (NSString * name in properties.allKeys)
    {
        if (![allColumns containsObject:name])
        {
            NSMutableString * sqlCreate = [[NSMutableString alloc] init];

            NSString * type = [properties valueForKey:name];
            NSString * sqlType = [mapTypeToSQLType valueForKey:type];
            
            [sqlCreate appendString:@"alter table "];
            [sqlCreate appendString:[self tableName]];
            [sqlCreate appendFormat:@" add column %@ %@", name, sqlType];

            @synchronized(CIX.DBLock) {
                [[CIX DB] executeUpdate:sqlCreate];
            }
        }
    }
}

/* Return the native type to SQL type mapping dictionary
 */
+(NSDictionary *)typeToSQLTypeMap
{
    return @{@"NSString" : @"TEXT",
             @"NSImage"  : @"BLOB",
             @"NSDate"   : @"DATETIME",
             @"i"        : @"INTEGER",
             @"B"        : @"INTEGER",
             @"c"        : @"INTEGER",
             @"q"        : @"INTEGER"};
}

/** Returns whether this class has an identity column
 
 @return YES if this class has an identity column, NO otherwise
 */
-(BOOL)hasIdentity
{
    return self.class.identityColumn != nil && class_getProperty(self.class, [[self.class identityColumn] UTF8String]) != nil;
}

/* Create the SQL statement to remove the record for this class from the database.
 */
-(void)delete
{
    NSMutableString * sqlCreate = [[NSMutableString alloc] init];
    id idValue = nil;

    if ([self hasIdentity])
        idValue = [self valueForKey:[self.class identityColumn]];
    
    [sqlCreate appendString:@"delete from "];
    [sqlCreate appendString:[self.class tableName]];
    
    if (idValue != nil)
        [sqlCreate appendFormat:@" where %@=%@", [self.class identityColumn], idValue];

    @synchronized(CIX.DBLock) {
        [CIX.DB executeUpdate:sqlCreate];
    }
}

/* Create the SQL statement to update the record for this class in the database.
 */
-(void)save
{
    id idValue = nil;
    
    if ([self hasIdentity])
    {
        idValue = [self valueForKey:[self.class identityColumn]] ;
        if ([idValue isKindOfClass:NSNumber.class] && [((NSNumber *)idValue) integerValue] == 0)
        {
            [self saveNew];
            return;
        }
    }
    
    NSMutableString * sqlCreate = [[NSMutableString alloc] init];
    
    [sqlCreate appendString:@"update "];
    [sqlCreate appendString:[self.class tableName]];
    [sqlCreate appendString:@" set "];
    
    NSDictionary * properties = [TableBase classPropsFor:self.class];
    NSString * separator = @"";
    
    NSMutableArray * values = [NSMutableArray array];
    
    for (NSString * name in properties.allKeys)
    {
        NSString * type = [properties valueForKey:name];
        NSString * value = [self valueForPropertyName:name andType:type];

        if ([name isEqualToString:[self.class identityColumn]])
            idValue = value;
        else
        {
            [sqlCreate appendFormat:@"%@%@=%@", separator, name, value];
            [values addObject:value];
        
            separator = @",";
        }
    }
    
    if (idValue != nil)
        [sqlCreate appendFormat:@" where %@=%@", [self.class identityColumn], idValue];
    
    @synchronized(CIX.DBLock) {
        [CIX.DB executeUpdate:sqlCreate];
    }
}

/* Create the SQL statement to insert a new record for this class into the database.
 */
-(void)saveNew
{
    NSMutableString * sqlCreate = [[NSMutableString alloc] init];
    NSMutableString * sqlMarkers = [[NSMutableString alloc] init];
    
    [sqlCreate appendString:@"insert into "];
    [sqlCreate appendString:[self.class tableName]];
    [sqlCreate appendString:@" ("];
    
    NSDictionary * properties = [TableBase classPropsFor:self.class];
    NSString * separator = @"";
    
    BOOL hasIdentity = NO;

    for (NSString * name in properties.allKeys)
    {
        NSString * type = [properties valueForKey:name];

        if ([name isEqualToString:[self.class identityColumn]])
            hasIdentity = YES;
        else
        {
            [sqlCreate appendFormat:@"%@%@", separator, name];

            NSString * value = [self valueForPropertyName:name andType:type];
            [sqlMarkers appendFormat:@"%@%@", separator, value];

            separator = @",";
        }
    }
    [sqlCreate appendFormat:@") values (%@)", sqlMarkers];

    @synchronized(CIX.DBLock) {
        [CIX.DB executeUpdate:sqlCreate];
        if (hasIdentity)
            [self setValue:[NSNumber numberWithLongLong:[CIX.DB lastInsertRowId]] forKey:[self.class identityColumn]];
    }
}

/** Returns a description of this object.
 */
-(NSString *)description
{
    NSMutableString * text = [NSMutableString stringWithFormat:@"<%@>\n", [self class]];

    NSDictionary * properties = [TableBase classPropsFor:self.class];
    for (NSString * name in properties.allKeys)
    {
        NSString * type = [properties valueForKey:name];
        NSString * value = [self valueForPropertyName:name andType:type];

        [text appendFormat:@"   [%@]: %@\n", name, value];
    }
    [text appendFormat:@"</%@>", [self class]];
    return text;
}

static const char * getPropertyType(objc_property_t property)
{
    const char *attributes = property_getAttributes(property);

    char buffer[1 + strlen(attributes)];
    strcpy(buffer, attributes);
    char *state = buffer, *attribute;
    while ((attribute = strsep(&state, ",")) != NULL)
    {
        if (attribute[0] == 'T' && attribute[1] != '@')
            return (const char *)[[NSData dataWithBytes:(attribute + 1) length:strlen(attribute) - 1] bytes];
        
        if (attribute[0] == 'T' && attribute[1] == '@' && strlen(attribute) == 2)
            return "id";
            
        if (attribute[0] == 'T' && attribute[1] == '@')
            return (const char *)[[NSData dataWithBytes:(attribute + 3) length:strlen(attribute) - 4] bytes];
    }
    return "";
}

+(NSDictionary *)classPropsFor:(Class)klass
{
    if (klass == NULL)
        return nil;
    
    NSMutableDictionary * results = [[NSMutableDictionary alloc] init];
    
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList(klass, &outCount);
    for (i = 0; i < outCount; i++)
    {
        objc_property_t property = properties[i];
        const char *propName = property_getName(property);
        if (propName != NULL)
        {
            const char *propType = getPropertyType(property);
            NSString *propertyName = [NSString stringWithUTF8String:propName];
            NSString *propertyType = [NSString stringWithUTF8String:propType];
            results[propertyName] = propertyType;
        }
    }
    free(properties);
    return [NSDictionary dictionaryWithDictionary:results];
}

-(NSString *)valueForPropertyName:(NSString *)name andType:(NSString *)type
{
    // Add the value as a safe string
    id value = [self valueForKey:name];
    if ([type isEqualToString:@"NSString"])
    {
        value = [value stringByReplacingOccurrencesOfString:@"'" withString:@"''"]; // Sanitize single quotes
        value = [NSString stringWithFormat:@"'%@'", SafeString(value)];
    }
    else if ([type isEqualToString:@"NSDate"])
        value = [NSString stringWithFormat:@"'%@'", [CIX.DB stringFromDate:value]];
    else if ([type isEqualToString:@"NSImage"])
        value = [value JFIFData:1.0];
    else
        value = SafeString([value stringValue]);
    return value;
}
@end
