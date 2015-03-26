//
//  BEModel.m
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import "BEModel.h"

#import <objc/message.h>
#import <objc/runtime.h>
#import "NSObject+Reflection.h"
#import "NSString+Tools.h"
#import "BEDB.h"
#import "BEThread.h"


@implementation BECacheItem
@end


@interface BEModel ()

@end


id getProperty(BEModel *self, SEL selector)
{
    return [self internalValueForProperty:[self selectorToPropertyName:selector]];
}

void setProperty(BEModel *self, SEL selector, id value)
{
    [self setInternalValue:value forProperty:[self selectorToPropertyName:selector]];
}

id getJSONSerializableProperty(BEModel *self, SEL selector)
{
    NSString *raw = [self internalValueForProperty:[self selectorToPropertyName:selector]];
    if (raw) {
        NSData *data = [raw dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        return [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    } else {
        return nil;
    }
}

void setJSONSerializableProperty(BEModel *self, SEL selector, id value)
{
    NSString *raw = nil;
    if (value) {
        NSError *error = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:value options:0 error:&error];
        raw = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    [self setInternalValue:raw forProperty:[self selectorToPropertyName:selector]];
}

NSData* getNSDataProperty(BEModel *self, SEL selector)
{
    return [self dataForProperty:[self selectorToPropertyName:selector]];
}

void setNSDataProperty(BEModel *self, SEL selector, NSData *value)
{
    [self cacheItem:value forProperty:[self selectorToPropertyName:selector]];
}

UIImage* getUIImageProperty(BEModel *self, SEL selector)
{
    return [self imageForProperty:[self selectorToPropertyName:selector]];
}

void setUIImageProperty(BEModel *self, SEL selector, UIImage *value)
{
    [self cacheItem:value forProperty:[self selectorToPropertyName:selector]];
}

NSDate* getNSDateProperty(BEModel *self, SEL selector)
{
    NSTimeInterval seconds = [[self internalValueForProperty:[self selectorToPropertyName:selector]] doubleValue];
    return [NSDate dateWithTimeIntervalSince1970:seconds];
}

void setNSDateProperty(BEModel *self, SEL selector, NSDate *value)
{
    NSTimeInterval seconds = [value timeIntervalSince1970];
    [self setInternalValue:[NSNumber numberWithDouble:seconds] forProperty:[self selectorToPropertyName:selector]];
}

char getCharProperty(BEModel *self, SEL selector)
{
    return [[self internalValueForProperty:[self selectorToPropertyName:selector]] charValue];
}

void setCharProperty(BEModel *self, SEL selector, char value)
{
    [self setInternalValue:[NSNumber numberWithChar:value] forProperty:[self selectorToPropertyName:selector]];
}

NSInteger getNSIntegerProperty(BEModel *self, SEL selector)
{
    return [[self internalValueForProperty:[self selectorToPropertyName:selector]] integerValue];
}

void setNSIntegerProperty(BEModel *self, SEL selector, NSInteger value)
{
    [self setInternalValue:[NSNumber numberWithInteger:value] forProperty:[self selectorToPropertyName:selector]];
}

NSUInteger getNSUIntegerProperty(BEModel *self, SEL selector)
{
    return [[self internalValueForProperty:[self selectorToPropertyName:selector]] unsignedIntegerValue];
}

void setNSUIntegerProperty(BEModel *self, SEL selector, NSUInteger value)
{
    [self setInternalValue:[NSNumber numberWithUnsignedInteger:value] forProperty:[self selectorToPropertyName:selector]];
}

CGFloat getCGFloatProperty(BEModel *self, SEL selector)
{
    return [[self internalValueForProperty:[self selectorToPropertyName:selector]] floatValue];
}

void setCGFloatProperty(BEModel *self, SEL selector, CGFloat value)
{
    [self setInternalValue:[NSNumber numberWithFloat:value] forProperty:[self selectorToPropertyName:selector]];
}

CGRect getCGRectProperty(BEModel *self, SEL selector)
{
    return CGRectFromString([self internalValueForProperty:[self selectorToPropertyName:selector]]);
}

void setCGRectProperty(BEModel *self, SEL selector, CGRect value)
{
    [self setInternalValue:NSStringFromCGRect(value) forProperty:[self selectorToPropertyName:selector]];
}

CGPoint getCGPointProperty(BEModel *self, SEL selector)
{
    return CGPointFromString([self internalValueForProperty:[self selectorToPropertyName:selector]]);
}

void setCGPointProperty(BEModel *self, SEL selector, CGPoint value)
{
    [self setInternalValue:NSStringFromCGPoint(value) forProperty:[self selectorToPropertyName:selector]];
}

CGAffineTransform getCGAffineTransformProperty(BEModel *self, SEL selector)
{
    return CGAffineTransformFromString([self internalValueForProperty:[self selectorToPropertyName:selector]]);
}

void setCGAffineTransformProperty(BEModel *self, SEL selector, CGAffineTransform value)
{
    [self setInternalValue:NSStringFromCGAffineTransform(value) forProperty:[self selectorToPropertyName:selector]];
}


@implementation BEModel

static NSMutableDictionary *_tableForClass;
static NSMutableDictionary *_primaryKeyForClass;
static NSMutableDictionary *_indexesForClass;
static NSMutableDictionary *_columnsForClass;
static NSMutableDictionary *_columnToPropertyMapForClass;
static NSMutableDictionary *_propertyToColumnMapForClass;

+ (void)initialize
{
    @synchronized(self) {
        if (!_tableForClass) {
            _tableForClass = [NSMutableDictionary dictionary];
        }
        if (!_primaryKeyForClass) {
            _primaryKeyForClass = [NSMutableDictionary dictionary];
        }
        if (!_indexesForClass) {
            _indexesForClass = [NSMutableDictionary dictionary];
        }
        if (!_columnsForClass) {
            _columnsForClass = [NSMutableDictionary dictionary];
        }
        if (!_columnToPropertyMapForClass) {
            _columnToPropertyMapForClass = [NSMutableDictionary dictionary];
        }
        if (!_propertyToColumnMapForClass) {
            _propertyToColumnMapForClass = [NSMutableDictionary dictionary];
        }
    }

    for(NSString *property in self.class.propertyToColumnMap) {
        NSString *propertyType = [self typeOfProperty:property];
        SEL getSelector = NSSelectorFromString(property);
        SEL setSelector = NSSelectorFromString([NSString stringWithFormat:@"set%@%@:",
                                                [[property substringToIndex:1] uppercaseString],
                                                [property substringFromIndex:1]]);
        if([propertyType isEqualToString:@"char"]) {
            class_addMethod(self.class, getSelector, (IMP)getCharProperty, "c@:");
            class_addMethod(self.class, setSelector, (IMP)setCharProperty, "v@:c");
        } else if([propertyType isEqualToString:@"int"] || [propertyType isEqualToString:@"bool"]) {
            class_addMethod(self.class, getSelector, (IMP)getNSIntegerProperty, "i@:");
            class_addMethod(self.class, setSelector, (IMP)setNSIntegerProperty, "v@:i");
        } else if([propertyType isEqualToString:@"unsigned int"]) {
            class_addMethod(self.class, getSelector, (IMP)getNSUIntegerProperty, "I@:");
            class_addMethod(self.class, setSelector, (IMP)setNSUIntegerProperty, "v@:I");
        } else if([propertyType isEqualToString:@"long"]) {
            class_addMethod(self.class, getSelector, (IMP)getNSIntegerProperty, "l@:");
            class_addMethod(self.class, setSelector, (IMP)setNSIntegerProperty, "v@:l");
        } else if([propertyType isEqualToString:@"unsigned long"]) {
            class_addMethod(self.class, getSelector, (IMP)getNSUIntegerProperty, "L@:");
            class_addMethod(self.class, setSelector, (IMP)setNSUIntegerProperty, "v@:L");
        } else if([propertyType isEqualToString:@"float"]) {
            class_addMethod(self.class, getSelector, (IMP)getCGFloatProperty, "f@:");
            class_addMethod(self.class, setSelector, (IMP)setCGFloatProperty, "v@:f");
        } else if([propertyType isEqualToString:@"double"]) {
            class_addMethod(self.class, getSelector, (IMP)getCGFloatProperty, "d@:");
            class_addMethod(self.class, setSelector, (IMP)setCGFloatProperty, "v@:d");
        } else if([propertyType isEqualToString:@"CGRect"]) {
            class_addMethod(self.class, getSelector, (IMP)getCGRectProperty, "{}@:");
            class_addMethod(self.class, setSelector, (IMP)setCGRectProperty, "v@:{}");
        } else if([propertyType isEqualToString:@"CGPoint"]) {
            class_addMethod(self.class, getSelector, (IMP)getCGPointProperty, "{}@:");
            class_addMethod(self.class, setSelector, (IMP)setCGPointProperty, "v@:{}");
        } else if([propertyType isEqualToString:@"CGAffineTransform"]) {
            class_addMethod(self.class, getSelector, (IMP)getCGAffineTransformProperty, "{}@:");
            class_addMethod(self.class, setSelector, (IMP)setCGAffineTransformProperty, "v@:{}");
        } else if([propertyType isEqualToString:@"NSData"]) {
            class_addMethod(self.class, getSelector, (IMP)getNSDataProperty, "@@:");
            class_addMethod(self.class, setSelector, (IMP)setNSDataProperty, "v@:@");
        } else if([propertyType isEqualToString:@"UIImage"]) {
            class_addMethod(self.class, getSelector, (IMP)getUIImageProperty, "@@:");
            class_addMethod(self.class, setSelector, (IMP)setUIImageProperty, "v@:@");
        } else if([propertyType isEqualToString:@"NSDate"]) {
            class_addMethod(self.class, getSelector, (IMP)getNSDateProperty, "@@:");
            class_addMethod(self.class, setSelector, (IMP)setNSDateProperty, "v@:@");
        } else if([propertyType isEqualToString:@"NSDictionary"]) {
            class_addMethod(self.class, getSelector, (IMP)getJSONSerializableProperty, "@@:");
            class_addMethod(self.class, setSelector, (IMP)setJSONSerializableProperty, "v@:@");
        } else if([propertyType isEqualToString:@"NSArray"]) {
            class_addMethod(self.class, getSelector, (IMP)getJSONSerializableProperty, "@@:");
            class_addMethod(self.class, setSelector, (IMP)setJSONSerializableProperty, "v@:@");
        } else {
            class_addMethod(self.class, getSelector, (IMP)getProperty, "@@:");
            class_addMethod(self.class, setSelector, (IMP)setProperty, "v@:@");
        }
    }
}

+ (NSString *)table
{
    if(!_tableForClass[self.class]) {
        _tableForClass[(id<NSCopying>)self.class] = [self.class getTable];
    }
    return _tableForClass[self.class];
}

+ (NSString *)primaryKey
{
    if(!_primaryKeyForClass[self.class]) {
        _primaryKeyForClass[(id<NSCopying>)self.class] = [self.class getPrimaryKey];
    }
    return _primaryKeyForClass[self.class];
}

+ (NSArray *)indexes
{
    if(!_indexesForClass[self.class]) {
        _indexesForClass[(id<NSCopying>)self.class] = [self.class getIndexes];
    }
    return _indexesForClass[self.class];
}

+ (NSDictionary *)columns
{
    if(!_columnsForClass[self.class]) {
        _columnsForClass[(id<NSCopying>)self.class] = [self.class getColumns];
    }
    return _columnsForClass[self.class];
}

+ (NSDictionary *)columnToPropertyMap
{
    if(!_columnToPropertyMapForClass[self.class]) {
        _columnToPropertyMapForClass[(id<NSCopying>)self.class] = [self.class getColumnToPropertyMap];
    }
    return _columnToPropertyMapForClass[self.class];
}

+ (NSDictionary *)propertyToColumnMap
{
    if(!_propertyToColumnMapForClass[self.class]) {
        _propertyToColumnMapForClass[(id<NSCopying>)self.class] = [self.class getPropertyToColumnMap];
    }
    return _propertyToColumnMapForClass[self.class];
}

+ (NSString *)getTable
{
    NSString *name = NSStringFromClass(self.class);
    if([name hasPrefix:@"BE"]) {
        name = [name substringFromIndex:2];
    }
    return [name camelCaseToUnderscore];
}

+ (NSString *)getPrimaryKey
{
    return @"pk";
}

+ (NSDictionary *)getPropertyToColumnMap
{
    u_int count;
    objc_property_t* propertyList = class_copyPropertyList(self.class, &count);
    NSMutableDictionary* propertyToColumnMap = [NSMutableDictionary dictionaryWithCapacity:count];
    for(int i = 0; i < count; i++) {
        NSString *propertyAttrs = @(property_getAttributes(propertyList[i]));
        if([propertyAttrs rangeOfString:@",R,"].location == NSNotFound &&
           [propertyAttrs rangeOfString:@",D,"].location != NSNotFound) {
            NSString *property = @(property_getName(propertyList[i]));
            if(![property hasPrefix:@"_"]) {
                propertyToColumnMap[property] = [property camelCaseToUnderscore];
            }
        }
    }
    free(propertyList);
    return propertyToColumnMap;
}

+ (NSDictionary *)getColumnToPropertyMap
{
    NSDictionary *propertyToColumnMap = self.class.propertyToColumnMap;
    NSMutableDictionary* columnToPropertyMap = [NSMutableDictionary dictionaryWithCapacity:propertyToColumnMap.count];
    for(NSString *property in propertyToColumnMap) {
        columnToPropertyMap[propertyToColumnMap[property]] = property;
    }
    return columnToPropertyMap;
}

+ (NSArray *)getIndexes
{
    return @[];
}

+ (NSDictionary *)getColumns
{
    NSDictionary *propertyToColumnMap = self.class.propertyToColumnMap;
    NSMutableDictionary* columns = [NSMutableDictionary dictionaryWithCapacity:propertyToColumnMap.count];
    for(NSString *property in propertyToColumnMap) {
        NSString *column = propertyToColumnMap[property];
        columns[column] = [self sqlForColumn:column];
    }
    return columns;
}

+ (NSString *)sqlForColumn:(NSString *)column
{
    NSString *property = self.class.columnToPropertyMap[column];
    NSString *primaryKey = self.class.primaryKey;
    NSString *dbType = @"TEXT";
    NSString *type = [self typeOfProperty:property];
    if([type isEqualToString:@"char"] ||
       [type isEqualToString:@"int"] ||
       [type isEqualToString:@"short"] ||
       [type isEqualToString:@"long"] ||
       [type isEqualToString:@"long long"] ||
       [type isEqualToString:@"unsigned int"] ||
       [type isEqualToString:@"unsigned short"] ||
       [type isEqualToString:@"unsigned long"] ||
       [type isEqualToString:@"unsigned long long"]) {
        dbType = @"INTEGER";
    } else if([type isEqualToString:@"float"] ||
              [type isEqualToString:@"double"] ||
              [type isEqualToString:@"NSDate"]) {
        dbType = @"REAL";
    }
    NSString *columnSpec = [NSString stringWithFormat:@"%@ %@", column, dbType];
    if([column isEqualToString:primaryKey]) {
        return [NSString stringWithFormat:@"%@ PRIMARY KEY", columnSpec];
    } else {
        return columnSpec;
    }
}

+ (NSDictionary *)fileProperties
{
    u_int count;
    objc_property_t* propertyList = class_copyPropertyList(self.class, &count);
    NSMutableDictionary* fileProperties = [NSMutableDictionary dictionaryWithCapacity:count];
    for(int i = 0; i < count; i++) {
        NSString *propertyName = @(property_getName(propertyList[i]));
        NSString *propertyType = [self typeOfProperty:propertyName];
        if([propertyType isEqualToString:@"UIImage"] || [propertyType isEqualToString:@"NSData"]) {
            fileProperties[propertyName] = [propertyName camelCaseToUnderscore];
        }
    }
    free(propertyList);
    return fileProperties;
}

+ (NSString *)generateFilename
{
    return [NSString uuid];
}

+ (NSString *)pathForFilename:(NSString *)filename
{
    return [BEDB.pathForFiles stringByAppendingPathComponent:filename];
}

@synthesize fileCache = _fileCache;
@synthesize dirtyProperties = _dirtyProperties;
@synthesize internalValues = _internalValues;

- (id)init
{
    self = [super init];
    if(self) {
        _dirtyProperties = [NSMutableDictionary dictionary];
        _internalValues = [NSMutableDictionary dictionary];
        _fileCache = [[NSCache alloc] init];
        _fileCache.delegate = self;
    }
    return self;
}

- (void)dealloc
{
    _fileCache.delegate = nil;
}

- (BOOL)isDirty
{
    return (self.dirtyProperties.count > 0);
}

- (NSDictionary *)columnValues
{
    NSMutableDictionary *columnValues = [NSMutableDictionary dictionaryWithCapacity:self.internalValues.count];
    for(NSString *property in self.internalValues) {
        columnValues[self.class.propertyToColumnMap[property]] = self.internalValues[property];
    }
    return columnValues;
}

- (void)setInternalValue:(id)value forProperty:(NSString *)property
{
    [self setInternalValue:value forProperty:property markDirty:YES];
}

- (void)setInternalValue:(id)value forProperty:(NSString *)property markDirty:(BOOL)dirty
{
    if(!value) {
        value = [NSNull null];
    }
    if(dirty) {
        id oldValue;
        if(self.dirtyProperties[property]) {
            oldValue = self.dirtyProperties[property][@"oldValue"];
        } else if(self.internalValues[property]) {
            oldValue = self.internalValues[property];
        } else {
            oldValue = [NSNull null];
        }
        self.dirtyProperties[property] = @{@"oldValue": oldValue, @"newValue": value};
    }
    self.internalValues[property] = value;
}

- (id)internalValueForProperty:(NSString *)property
{
    id value = self.internalValues[property];
    if([[NSNull null] isEqual:value]) {
        return nil;
    } else {
        return value;
    }
}

- (BOOL)markFilesForDeletion
{
    @try {
        for(NSString *property in [self.class fileProperties]) {
            NSString *filename = [self internalValueForProperty:property];
            if(filename) {
                NSString *path = [self.class pathForFilename:filename];
                if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                    NSError *error = nil;
                    NSString *deletedPath = [NSString stringWithFormat:@"%@.deleted", path];
                    BOOL success = [[NSFileManager defaultManager] moveItemAtPath:path toPath:deletedPath error:&error];
                    if (error) {
                        NSLog(@"Error marking file for property: %@\n%@", property, error);
                        return NO;
                    }
                    if (!success) {
                        NSLog(@"Failed marking file for property: %@", property);
                        return NO;
                    }
                }
            }
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception marking files for deletion:\n%@", exception);
        return NO;
    }
    return YES;
}

- (BOOL)restoreFilesMarkedForDeletion
{
    @try {
        for(NSString *property in [self.class fileProperties]) {
            NSString *filename = [self internalValueForProperty:property];
            if(filename) {
                NSString *path = [self.class pathForFilename:filename];
                NSString *deletedPath = [NSString stringWithFormat:@"%@.deleted", path];
                if([[NSFileManager defaultManager] fileExistsAtPath:deletedPath]) {
                    NSError *error = nil;
                    BOOL success = [[NSFileManager defaultManager] moveItemAtPath:deletedPath toPath:path error:&error];
                    if (error) {
                        NSLog(@"Error restoring file for property: %@\n%@", property, error);
                        return NO;
                    }
                    if (!success) {
                        NSLog(@"Failed restoring file for property: %@", property);
                        return NO;
                    }
                }
            }
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception restoring marked files:\n%@", exception);
        return NO;
    }
    return YES;
}

- (BOOL)deleteFiles
{
    for(NSString *property in [self.class fileProperties]) {
        if(![self deleteFileForProperty:property]) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)deleteFileForProperty:(NSString *)property
{
    @try {
        NSString *filename = [self internalValueForProperty:property];
        if(filename) {
            NSString *path = [self.class pathForFilename:filename];
            if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                NSError *error = nil;
                [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
                if(error) {
                    NSLog(@"Failed deleting file for property: %@\n%@", property, error);
                    return NO;
                }
            }
            NSString *deletedPath = [NSString stringWithFormat:@"%@.deleted", path];
            if([[NSFileManager defaultManager] fileExistsAtPath:deletedPath]) {
                NSError *error = nil;
                [[NSFileManager defaultManager] removeItemAtPath:deletedPath error:&error];
                if(error) {
                    NSLog(@"Failed deleting marked file for property: %@\n%@", property, error);
                    return NO;
                }
            }
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Error deleting file for property: %@\n%@", property, exception);
        return NO;
    }
    return YES;
}

- (void)saveFiles:(void(^)(BOOL success))completion
{
    [BEThread background:^{
        for(NSString *property in [self.class fileProperties]) {
            if ([self.dirtyProperties objectForKey:property]) {
                if(![self saveFileForProperty:property]) {
                    if(completion) {
                        completion(NO);
                    }
                    return;
                }
            }
        }
        if(completion) {
            completion(YES);
        }
    }];
}

- (BOOL)saveFileForProperty:(NSString *)property
{
    @try {
        SEL selector = NSSelectorFromString(property);
        id item = objc_msgSend(self, selector);
        if(item) {
            NSString *filename = [self internalValueForProperty:property];
            if(!filename) {
                filename = [self.class generateFilename];
                [self setInternalValue:filename forProperty:property];
            }
            [self saveItem:item filename:filename];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Error saving file for property: %@\n%@", property, exception);
        return NO;
    }
    return YES;
}

- (BOOL)saveItem:(id)item filename:(NSString *)filename
{
    @try {
        if(item) {
            NSString *path = [self.class pathForFilename:filename];
            if(![[NSFileManager defaultManager] fileExistsAtPath:path]) {
                NSData *data = item;
                if([item isKindOfClass:UIImage.class]) {
                    data = UIImagePNGRepresentation((UIImage *)item);
                }
                if(![data writeToFile:path atomically:YES]) {
                    NSLog(@"Failed saving file to path: %@", path);
                    return NO;
                }
            }
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Error saving file:\n%@", exception);
        return NO;
    }
    return YES;
}

- (UIImage *)imageForProperty:(NSString *)property
{
    @synchronized(self) {
        BECacheItem *cacheItem = [self.fileCache objectForKey:property];
        UIImage *image = cacheItem.item;
        if(!image) {
            NSString *filename = [self internalValueForProperty:property];
            if(filename) {
                NSString *path = [self.class pathForFilename:filename];
                if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                    NSString *path = [self.class pathForFilename:filename];
                    image = [UIImage imageWithData:[NSData dataWithContentsOfFile:path]];
                }
            }
        }
        return image;
    }
}

- (NSData *)dataForProperty:(NSString *)property
{
    @synchronized(self) {
        BECacheItem *cacheItem = [self.fileCache objectForKey:property];
        NSData *data = cacheItem.item;
        if(!data) {
            NSString *filename = [self internalValueForProperty:property];
            if(filename) {
                NSString *path = [self.class pathForFilename:filename];
                if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                    NSString *path = [self.class pathForFilename:filename];
                    data = [NSData dataWithContentsOfFile:path];
                }
            }
        }
        return data;
    }
}

- (void)cacheItem:(id)item forProperty:(NSString *)property
{
    @synchronized(self) {
        NSString *existingFilename = [self internalValueForProperty:property];
        if(existingFilename) {
            NSString *existingPath = [self.class pathForFilename:existingFilename];
            if([[NSFileManager defaultManager] fileExistsAtPath:existingPath]) {
                [[NSFileManager defaultManager] removeItemAtPath:existingPath error:nil];
            }
        }
        if(item) {
            BECacheItem *cacheItem = [[BECacheItem alloc] init];
            cacheItem.item = item;
            cacheItem.property = property;
            [self setInternalValue:[self.class generateFilename] forProperty:property];
            [self.fileCache setObject:cacheItem forKey:property];
        } else {
            [self setInternalValue:nil forProperty:property];
            [self.fileCache removeObjectForKey:property];
        }
    }
}

- (void)cache:(NSCache *)cache willEvictObject:(id)obj
{
    BECacheItem *cacheItem = obj;
    if ([self.dirtyProperties objectForKey:cacheItem.property]) {
        NSString *filename = [self internalValueForProperty:cacheItem.property];
        if (filename) {
            id item = cacheItem.item;
            [BEThread background:^{
                [self saveItem:item filename:filename];
            }];
        }
    }
}

@end
