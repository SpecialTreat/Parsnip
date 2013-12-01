#import <Foundation/Foundation.h>


@interface BECacheItem : NSObject
@property (nonatomic) NSString *property;
@property (nonatomic) id item;
@end


@interface BEModel : NSObject<NSCacheDelegate>

+ (NSString *)getTable;
+ (NSString *)getPrimaryKey;
+ (NSArray *)getIndexes;
+ (NSDictionary *)getColumns;
+ (NSDictionary *)getColumnToPropertyMap;
+ (NSDictionary *)getPropertyToColumnMap;
+ (NSString *)sqlForColumn:(NSString *)column;

+ (NSString *)table;
+ (NSString *)primaryKey;
+ (NSArray *)indexes;
+ (NSDictionary *)columns;
+ (NSDictionary *)columnToPropertyMap;
+ (NSDictionary *)propertyToColumnMap;

+ (NSDictionary *)fileProperties;
+ (NSString *)generateFilename;
+ (NSString *)pathForFilename:(NSString *)filename;

@property (nonatomic, readonly) BOOL isDirty;
@property (nonatomic, readonly) NSDictionary *columnValues;
@property (nonatomic) NSMutableDictionary *dirtyProperties;
@property (nonatomic) NSMutableDictionary *internalValues;

@property (nonatomic, readonly) NSCache *fileCache;

- (BOOL)markFilesForDeletion;
- (BOOL)restoreFilesMarkedForDeletion;
- (BOOL)deleteFiles;
- (BOOL)deleteFileForProperty:(NSString *)property;
- (void)saveFiles:(void(^)(BOOL success))completion;
- (BOOL)saveFileForProperty:(NSString *)property;

- (id)internalValueForProperty:(NSString *)property;
- (void)setInternalValue:(id)value forProperty:(NSString *)property;
- (void)setInternalValue:(id)value forProperty:(NSString *)property markDirty:(BOOL)dirty;

- (UIImage *)imageForProperty:(NSString *)property;
- (NSData *)dataForProperty:(NSString *)property;
- (void)cacheItem:(id)item forProperty:(NSString *)property;

- (void)cache:(NSCache *)cache willEvictObject:(id)obj;

@end
