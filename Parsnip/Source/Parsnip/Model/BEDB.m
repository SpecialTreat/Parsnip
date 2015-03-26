//
//  BEDB.m
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import "BEDB.h"

#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "BENote.h"


@implementation BEDB

static FMDatabaseQueue *_queue = nil;
static NSString *_pathForFiles = nil;
static NSString *_pathForDB = nil;
static BOOL _debug = NO;
static BOOL _needsInitialData;

+ (void)initialize
{
    _needsInitialData = ![[NSFileManager defaultManager] fileExistsAtPath:BEDB.pathForDB];
    [BEDB queue];
}

+ (void)setDebug:(BOOL)debug
{
    _debug = debug;
}

+ (BOOL)needsInitialData
{
    return _needsInitialData;
}

+ (FMDatabaseQueue *)queue
{
    if(!_queue) {
        _queue = [FMDatabaseQueue databaseQueueWithPath:BEDB.pathForDB];
    }
    return _queue;
}

+ (NSString *)pathForFiles
{
    if(!_pathForFiles) {
        NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentPath = ([documentPaths count] > 0) ? [documentPaths objectAtIndex:0] : nil;
        _pathForFiles = [documentPath stringByAppendingPathComponent:@"BEDBFiles"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if(![fileManager fileExistsAtPath:_pathForFiles]) {
            [fileManager createDirectoryAtPath:_pathForFiles withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
    return _pathForFiles;
}

+ (NSString *)pathForDB
{
    if(!_pathForDB) {
        NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentPath = ([documentPaths count] > 0) ? [documentPaths objectAtIndex:0] : nil;
        _pathForDB = [documentPath stringByAppendingPathComponent:@"BEDB.db"];
    }
    return _pathForDB;
}

+ (void)loadInitialData
{
    NSError *error = nil;
    BOOL isDir = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSString *initialDataPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"InitialData"];
    NSString *initialFilesPath = [initialDataPath stringByAppendingPathComponent:@"BEDBFiles"];

    if ([fileManager fileExistsAtPath:initialFilesPath isDirectory:&isDir] && isDir) {
        NSArray *files = [fileManager contentsOfDirectoryAtPath:initialFilesPath error:&error];
        for (NSString *fileName in files) {
            NSString *path = [initialFilesPath stringByAppendingPathComponent:fileName];
            error = nil;
            [fileManager copyItemAtPath:path toPath:[BEDB.pathForFiles stringByAppendingPathComponent:fileName] error:&error];
            if (error) {
                NSLog(@"Error copying initial file: %@\n%@", path, error);
                break;
            }
        }

        if (!error) {
            files = [[fileManager contentsOfDirectoryAtPath:initialDataPath error:&error] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
            for (NSString *fileName in files) {
                if ([fileName hasSuffix:@".json"]) {
                    NSString *path = [initialDataPath stringByAppendingPathComponent:fileName];
                    if ([fileManager fileExistsAtPath:path isDirectory:&isDir] && !isDir) {
                        NSInputStream *is = [[NSInputStream alloc] initWithFileAtPath:path];
                        [is open];
                        error = nil;
                        NSDictionary *values = [NSJSONSerialization JSONObjectWithStream:is options:0 error:&error];
                        [is close];
                        if (values && !error) {
                            BENote *note = [[BENote alloc] init];
                            NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
                            for (NSString *property in values) {
                                if ([property hasSuffix:@"Timestamp"]) {
                                    [note setInternalValue:[NSNumber numberWithDouble:now] forProperty:property];
                                } else {
                                    [note setInternalValue:values[property] forProperty:property];
                                }
                            }
                            if (![BEDB save:note]) {
                                NSLog(@"Error saving initial data from: %@\n%@", path, error);
                            }
                        } else {
                            NSLog(@"Error reading initial data from: %@\n%@", path, error);
                        }
                    }
                }
            }
        }
    }
}

+ (void)register:(Class)cls
{
    [_queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db setTraceExecution:_debug];
        [db setLogsErrors:_debug];

        NSString *sql = [BEDB sqlForCreateTable:cls];
        [db executeUpdate:sql];

        NSString *table = [cls table];
        FMResultSet *dbColumnsResults = [db executeQuery:[NSString stringWithFormat:@"PRAGMA table_info(%@)", table]];
        NSMutableDictionary *dbColumns = [[NSMutableDictionary alloc] init];
        while ([dbColumnsResults next]) {
            dbColumns[[dbColumnsResults stringForColumn:@"name"]] = [dbColumnsResults stringForColumn:@"type"];
        }

        NSDictionary *columns = [cls columns];
        for(NSString *column in columns) {
            if (![dbColumns objectForKey:column]) {
                sql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@", table, columns[column]];
                [db executeUpdate:sql];
            }
        }

        FMResultSet *dbIndexResults = [db executeQuery:[NSString stringWithFormat:@"PRAGMA index_list(%@)", table]];
        NSMutableDictionary *dbIndexes = [[NSMutableDictionary alloc] init];
        while ([dbIndexResults next]) {
            NSString *indexName = [dbIndexResults stringForColumn:@"name"];
            if (indexName) {
                dbIndexes[indexName] = indexName;
            }
        }

        NSArray *indexes = [cls indexes];
        for(id property in indexes) {
            NSString *indexName = nil;
            NSString *columnSpec = nil;

            if ([property isKindOfClass:NSArray.class] && [property count]) {
                NSMutableArray *cols = [NSMutableArray array];
                for (NSString *p in property) {
                    NSString *c = [cls propertyToColumnMap][p];
                    if (c) {
                        [cols addObject:c];
                    }
                }
                if ([cols count]) {
                    indexName = [NSString stringWithFormat:@"%@__%@__index", table, [cols componentsJoinedByString:@"__"]];
                    columnSpec = [cols componentsJoinedByString:@", "];
                }
            } else if ([property isKindOfClass:NSString.class]) {
                NSString *column = [cls propertyToColumnMap][property];
                if (column) {
                    indexName = [NSString stringWithFormat:@"%@__%@__index", table, column];
                    columnSpec = column;
                }
            }
            if (indexName && columnSpec && !dbIndexes[indexName]) {
                NSString *sql = [NSString stringWithFormat:@"CREATE INDEX IF NOT EXISTS %@ ON %@ (%@)", indexName, table, columnSpec];
                [db executeUpdate:sql];
            }
        }
    }];
}

+ (NSString *)sqlForCreateTable:(Class)cls
{
    NSMutableArray *parts = [NSMutableArray array];
    [parts addObject:[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(", [cls table]]];
    NSDictionary *columns = [cls columns];
    NSMutableArray *columnParts = [NSMutableArray arrayWithCapacity:columns.count];
    NSArray *sortedColumns = [[columns allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    for(NSString *column in sortedColumns) {
        [columnParts addObject:[NSString stringWithFormat:@"    %@", columns[column]]];
    }
    [parts addObject:[columnParts componentsJoinedByString:@",\n"]];
    [parts addObject:@")"];
    return [parts componentsJoinedByString:@"\n"];
}

+ (NSString *)sqlForDelete:(BEModel *)model
{
    NSString *pk = [model.class primaryKey];
    return [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = :%@", [model.class table], pk, pk];
}

+ (NSString *)sqlForInsertOrReplace:(BEModel *)model
{
    if(!model.isDirty) {
        return nil;
    }

    NSMutableArray *parts = [NSMutableArray array];
    [parts addObject:[NSString stringWithFormat:@"INSERT OR REPLACE INTO %@ (", [model.class table]]];

    NSDictionary *columns = model.columnValues;
    
    NSMutableArray *columnParts = [NSMutableArray arrayWithCapacity:columns.count];
    NSMutableArray *valueParts = [NSMutableArray arrayWithCapacity:columns.count];

    NSArray *sortedColumns = [[columns allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    for(NSString *column in sortedColumns) {
        [columnParts addObject:[NSString stringWithFormat:@"    %@", column]];
        [valueParts addObject:[NSString stringWithFormat:@"    :%@", column]];
    }
    [parts addObject:[columnParts componentsJoinedByString:@",\n"]];
    [parts addObject:@") VALUES ("];
    [parts addObject:[valueParts componentsJoinedByString:@",\n"]];
    [parts addObject:@")"];
    return [parts componentsJoinedByString:@"\n"];
}

+ (NSString *)sqlForSelect:(Class)cls parameters:(NSDictionary *)parameters orderBy:(NSString *)orderBy asc:(BOOL)asc limit:(NSUInteger)limit offset:(NSUInteger)offset
{
    NSMutableArray *parts = [NSMutableArray array];
    [parts addObject:@"SELECT"];
    NSDictionary *columns = [cls columns];
    NSMutableArray *columnParts = [NSMutableArray arrayWithCapacity:columns.count];
    NSArray *sortedColumns = [[columns allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    for(NSString *column in sortedColumns) {
        [columnParts addObject:[NSString stringWithFormat:@"    %@", column]];
    }
    [parts addObject:[columnParts componentsJoinedByString:@",\n"]];
    [parts addObject:@"FROM"];
    [parts addObject:[NSString stringWithFormat:@"    %@", [cls table]]];

    if(parameters.count) {
        [parts addObject:@"WHERE"];
        NSMutableArray *queryParts = [NSMutableArray arrayWithCapacity:parameters.count];
        for(NSString *column in parameters) {
            NSString *param = [NSString stringWithFormat:@":%@", column];
            NSString *op = @"=";
            id value = parameters[column];
            if ([value isKindOfClass:NSArray.class] && [value count]) {
                op = [value objectAtIndex:0];
                if ([value count] == 1) {
                    param = @"";
                }
            }
            [queryParts addObject:[NSString stringWithFormat:@"    %@ %@ %@", column, op, param]];
        }
        [parts addObject:[queryParts componentsJoinedByString:@"\n    AND\n"]];
    }

    if (orderBy) {
        if (asc) {
            [parts addObject:[NSString stringWithFormat:@"ORDER BY %@ ASC", orderBy]];
        } else {
            [parts addObject:[NSString stringWithFormat:@"ORDER BY %@ DESC", orderBy]];
        }
    }

    if (limit > 0) {
        [parts addObject:[NSString stringWithFormat:@"LIMIT %lu", (unsigned long)limit]];
    }

    if (offset > 0) {
        [parts addObject:[NSString stringWithFormat:@"OFFSET %lu", (unsigned long)offset]];
    }

    return [parts componentsJoinedByString:@"\n"];
}

+ (NSDictionary *)prepareParameters:(NSDictionary *)parameters
{
    NSMutableDictionary *preparedParameters = [NSMutableDictionary dictionary];
    if (parameters && [parameters count]) {
        for(NSString *column in parameters) {
            id value = parameters[column];
            if ([value isKindOfClass:NSArray.class]) {
                if ([value count] > 1) {
                    preparedParameters[column] = value[1];
                }
            } else {
                preparedParameters[column] = value;
            }
        }
    }
    return preparedParameters;
}

+ (void)query:(NSString *)sql results:(void (^)(FMResultSet *results))block
{
    [BEDB query:sql parameters:nil results:block];
}

+ (void)query:(NSString *)sql parameters:(NSDictionary *)parameters results:(void (^)(FMResultSet *results))block
{
    parameters = [self prepareParameters:parameters];
    [_queue inDatabase:^(FMDatabase *db) {
        [db setTraceExecution:_debug];
        [db setLogsErrors:_debug];

        FMResultSet *results;
        if (parameters && [parameters count]) {
            results = [db executeQuery:sql withParameterDictionary:parameters];
            if (_debug) {
                NSLog(@"%@", parameters);
            }
        } else {
            results = [db executeQuery:sql];
        }
        if (block) {
            block(results);
        }
    }];
}
+ (NSInteger)count:(NSString *)sql
{
    return [BEDB count:sql parameters:nil];
}

+ (NSInteger)count:(NSString *)sql parameters:(NSDictionary *)parameters
{
    __block NSInteger count = 0;
    [BEDB query:sql parameters:parameters results:^(FMResultSet *results) {
        if ([results next]) {
            count = [results intForColumnIndex:0];
        }
        [results close];
    }];
    return count;
}

+ (BOOL)remove:(id)models
{
    NSArray *modelList;
    if([models isKindOfClass:NSArray.class]) {
        modelList = (NSArray *)models;
    } else {
        modelList = @[models];
    }
    __block BOOL success;
    [_queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db setTraceExecution:_debug];
        [db setLogsErrors:_debug];

        NSMutableArray *deletedModels = [NSMutableArray arrayWithCapacity:modelList.count];
        for(BEModel *model in modelList) {
            success = [BEDB removeInDatabase:db model:model removeFiles:NO];
            if (success) {
                success = [model markFilesForDeletion];
            }
            if (success) {
                [deletedModels addObject:model];
            } else {
                break;
            }
        }
        for (BEModel *model in deletedModels) {
            if (success) {
                [model deleteFiles];
            } else {
                [model restoreFilesMarkedForDeletion];
            }
        }
        if (!success) {
            *rollback = YES;
            return;
        }
    }];
    if (!success) {
        return NO;
    }
    return YES;
}

+ (BOOL)removeInDatabase:(FMDatabase *)db model:(BEModel *)model removeFiles:(BOOL)removeFiles
{
    NSString *sql = [BEDB sqlForDelete:model];
    NSString *pk = [model.class primaryKey];
    id pkValue = [model internalValueForProperty:pk];
    if (!pkValue) {
        return YES;
    } else if ([db executeUpdate:sql withParameterDictionary:@{pk: pkValue}]) {
        BOOL success = YES;
        if (removeFiles) {
            success = [model deleteFiles];
        }
        return success;
    } else {
        return NO;
    }
}

+ (BOOL)save:(id)models
{
    NSArray *modelList;
    if([models isKindOfClass:NSArray.class]) {
        modelList = (NSArray *)models;
    } else {
        modelList = @[models];
    }
    for(BEModel *model in modelList) {
        __block BOOL success;
        [_queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            [db setTraceExecution:_debug];
            [db setLogsErrors:_debug];

            success = [BEDB saveInDatabase:db model:model];
            if(!success) {
                *rollback = YES;
                return;
            }
        }];
        if (!success) {
            return NO;
        }
    }
    return YES;
}

+ (BOOL)saveInDatabase:(FMDatabase *)db model:(BEModel *)model
{
    NSString *sql = [BEDB sqlForInsertOrReplace:model];
    if([db executeUpdate:sql withParameterDictionary:model.columnValues]) {
        if (_debug) {
            NSLog(@"%@", model.columnValues);
        }
        NSString *pk = [model.class primaryKey];
        if (![model internalValueForProperty:pk]) {
            [model setInternalValue:[NSNumber numberWithInteger:[db lastInsertRowId]] forProperty:pk markDirty:NO];
        }
        [model saveFiles:nil];
        return YES;
    } else {
        if (_debug) {
            NSLog(@"%@", model.columnValues);
        }
        return NO;
    }
}

+ (id)get:(Class)cls pk:(id)pk
{
    NSArray *models = [BEDB get:cls parameters:@{[cls primaryKey]: pk}];
    if(models.count) {
        return [models objectAtIndex:0];
    } else {
        return nil;
    }
}

+ (NSArray *)get:(Class)cls parameters:(NSDictionary *)parameters
{
    return [BEDB get:cls parameters:parameters orderBy:nil asc:YES];
}

+ (NSArray *)get:(Class)cls parameters:(NSDictionary *)parameters orderBy:(NSString *)orderBy
{
    return [BEDB get:cls parameters:parameters orderBy:orderBy asc:YES limit:0 offset:0];
}

+ (NSArray *)get:(Class)cls parameters:(NSDictionary *)parameters orderBy:(NSString *)orderBy asc:(BOOL)asc
{
    return [BEDB get:cls parameters:parameters orderBy:orderBy asc:asc limit:0 offset:0];
}

+ (NSArray *)get:(Class)cls parameters:(NSDictionary *)parameters orderBy:(NSString *)orderBy asc:(BOOL)asc limit:(NSUInteger)limit offset:(NSUInteger)offset
{
    __block NSArray *models = [NSArray array];
    [_queue inDatabase:^(FMDatabase *db) {
        [db setTraceExecution:_debug];
        [db setLogsErrors:_debug];

        models = [BEDB getInDatabase:db modelClass:cls parameters:parameters orderBy:orderBy asc:asc limit:limit offset:offset];
    }];
    return models;
}

+ (NSArray *)getInDatabase:(FMDatabase *)db modelClass:(Class)cls parameters:(NSDictionary *)parameters orderBy:(NSString *)orderBy asc:(BOOL)asc limit:(NSUInteger)limit offset:(NSUInteger)offset
{
    NSMutableArray *models = [NSMutableArray array];
    NSString *sql = [BEDB sqlForSelect:cls parameters:parameters orderBy:orderBy asc:asc limit:limit offset:offset];
    parameters = [self prepareParameters:parameters];
    FMResultSet *rs = [db executeQuery:sql withParameterDictionary:parameters];
    if (_debug) {
        NSLog(@"%@", parameters);
    }
    while([rs next]) {
        BEModel *model = [[cls alloc] init];
        for(NSString *column in [[cls columns] allKeys]) {
            NSString *property = [cls columnToPropertyMap][column];
            id internalValue = [rs objectForColumnName:column];
            [model setInternalValue:internalValue forProperty:property markDirty:NO];
        }
        [models addObject:model];
    }
    return models;
}

@end
