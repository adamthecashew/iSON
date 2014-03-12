//
//  Created by Adam Fisch on 8/28/13.
//  Copyright (c) 2013 Adam Fisch. All rights reserved.
//

#import "iSON.h"
#import <objC/runtime.h>

@implementation iSON

static NSDateFormatter *dateFormatter;
static NSMutableDictionary *arrayTyping;

#pragma mark - create instance to be only created once
+ (id)sharedInstance
{
    static dispatch_once_t pred;
    static iSON *instance = nil;
    
    dispatch_once(&pred, ^{
        arrayTyping = [NSMutableDictionary new];
        instance = [iSON new];
    });
    
    return instance;
}

#pragma mark -
#pragma mark - Public API methods
+ (void)registerObjectByPropertyName:(NSString *)propertyName forClass:(Class)cls
{
    [[iSON sharedInstance] registerObjectByPropertyName:propertyName forClass:cls];
}

+ (Class)arrayTypeForPropertyName:(NSString *)propertyName
{
    return [[iSON sharedInstance] arrayTypeForPropertyName:propertyName];
}

+ (NSString *)objectToJSON:(id)object
{
    return  [[iSON sharedInstance] objectToJSON:object];
}

+ (id)objectFromJSON:(NSString *)JSON forClass:(Class)className
{
    return [[iSON sharedInstance] objectFromJSON:JSON forClass:className];
}

+ (NSArray *)objectFromUnnamedArrayJSON:(NSString *)JSON forClass:(Class)cls
{
    return [[iSON sharedInstance] objectFromUnnamedArrayJSON:JSON forClass:cls];
}

+ (NSString *)arrayToJSON:(NSArray *)items
{
    return [[iSON sharedInstance] arrayToJSON:items];
}

+ (void)setDateFormatter:(NSString *)dateFormat
{
    dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:dateFormat];
}

+ (NSString *)dictionaryToJSON:(NSDictionary *)dict
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    
    if (error) {
        NSLog(@"Unable to create json string from dictionary. Error - %@", [error localizedDescription]);
        return nil;
    }
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

#pragma mark -
#pragma mark - Private instance methods

#pragma mark -
#pragma mark - Array typing methods
- (Class)arrayTypeForPropertyName:(NSString *)propertyName
{
    if (![arrayTyping objectForKey:propertyName]){
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Property not registered to ISON" userInfo:nil];
    }
    
    return [arrayTyping objectForKey:propertyName];
}

- (void)registerObjectByPropertyName:(NSString *)propertyName forClass:(Class)cls
{
    if ([arrayTyping objectForKey:propertyName]) {
        if (![[arrayTyping objectForKey:propertyName] isEqual:cls]) {
            [arrayTyping removeObjectForKey:propertyName];
            [arrayTyping setObject:cls forKey:propertyName];
        }
        return;
    } else {
        [arrayTyping setObject:cls forKey:propertyName];
    }
}

#pragma mark -
#pragma mark - Serialization of an object to JSON
- (NSString *)arrayToJSON:(NSArray *)items
{
    NSMutableArray *array = [NSMutableArray new];
    
    for (id object in items) {
        NSDictionary *dict = [self toJSONForObject:object];
        [array addObject:dict];
    }
    
    NSError *jsonError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:array options:NSJSONWritingPrettyPrinted error:&jsonError];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}
- (NSString *)objectToJSON:(id)object
{
    Class class = [object class];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    Class superClass = class_getSuperclass(class);
    [self addSuperClass:superClass toDictionary:dict forObject:object];
    
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList(class, &outCount);
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        NSString *propertyName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        SEL propertySelector = NSSelectorFromString(propertyName);
        if ([object respondsToSelector:propertySelector]) {
            id value = [object performSelector:propertySelector];
            if ([value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSDictionary class]] || [value isMemberOfClass:[NSNumber class]]) {
                [dict setValue:value forKey:propertyName];
            } else if ([value isKindOfClass:[NSArray class]]) {
                NSMutableArray *array = [NSMutableArray new];
                for (id obj in value) {
                    [array addObject:[self toJSONForObject:obj]];
                }
                [dict setValue:array forKey:propertyName];
            } else if ([value isKindOfClass:[NSDate class]]) {
                [dict setValue:[self formatDate:value] forKey:propertyName];
            } else if ([value isKindOfClass:[NSObject class]]) {
                [dict setValue:[self toJSONForObject:value] forKey:propertyName];
            } else if (!value) {
                [dict setValue:[NSNull new] forKey:propertyName];
            } else {
                @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Object was not NSNumber, NSObject, NSArray, NSDictionary or NSString" userInfo:nil];
            }
        }
    }
    NSError *jsonError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&jsonError];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (void)addSuperClass:(Class)class toDictionary:(NSMutableDictionary *)dict forObject:(id)object
{
    if (class == [NSObject class]) {
        return;
    }
    
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList(class, &outCount);
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        NSString *propertyName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        SEL propertySelector = NSSelectorFromString(propertyName);
        if ([object respondsToSelector:propertySelector]) {
            id value = [object performSelector:propertySelector];
            if ([value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSDictionary class]] || [value isMemberOfClass:[NSNumber class]]) {
                [dict setValue:value forKey:propertyName];
            } else if ([value isKindOfClass:[NSArray class]]) {
                NSMutableArray *array = [NSMutableArray new];
                for (id obj in value) {
                    [array addObject:[self toJSONForObject:obj]];
                }
                [dict setValue:array forKey:propertyName];
            } else if ([value isKindOfClass:[NSDate class]]) {
                [dict setValue:[self formatDate:value] forKey:propertyName];
            } else if ([value isKindOfClass:[NSObject class]]) {
                [dict setValue:[self toJSONForObject:value] forKey:propertyName];
            } else if (!value) {
                [dict setValue:[NSNull new] forKey:propertyName];
            } else {
                @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Object was not NSNumber, NSObject, NSArray, NSDictionary or NSString" userInfo:nil];
            }
        }
    }
}

- (NSMutableDictionary *)toJSONForObject:(id)object
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList([object class], &outCount);
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        NSString *propertyName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        SEL propertySelector = NSSelectorFromString(propertyName);
        if ([object respondsToSelector:propertySelector]) {
            id value = [object performSelector:propertySelector];
            if ([value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSDictionary class]] || [value isMemberOfClass:[NSNumber class]]) {
                [dict setValue:value forKey:propertyName];
            } else if ([value isKindOfClass:[NSArray class]]) {
                NSMutableArray *array = [NSMutableArray new];
                for (id obj in value) {
                    [array addObject:[self toJSONForObject:obj]];
                }
                [dict setValue:array forKey:propertyName];
            } else if ([value isKindOfClass:[NSDate class]]) {
                [dict setValue:[self formatDate:value] forKey:propertyName];
            } else if ([value isKindOfClass:[NSObject class]]) {
                [dict setValue:[self toJSONForObject:value] forKey:propertyName];
            } else if (!value) {
                [dict setValue:[NSNull new] forKey:propertyName];
            } else {
                @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Object was not NSNumber, NSObject, NSArray, NSDictionary or NSString" userInfo:nil];
            }
        }
    }
    return dict;
}

#pragma mark -
#pragma mark - Deserialization of JSON to an object
- (NSArray *)objectfromUnnamedArrayJSON:(NSString *)JSON forClass:(Class)cls
{
    NSMutableArray *items = [NSMutableArray new];
    
    NSArray *objects = [self arrayFromJSON:JSON];
    for (NSDictionary *object in objects) {
        id item = [self dictionaryToObject:object forClass:NSStringFromClass(cls)];
        [items addObject:item];
    }
    return [NSArray arrayWithArray:items];
}

- (id)objectFromJSON:(NSString *)JSON forClass:(Class)className
{
    id newObject = [className new];
    
    NSDictionary *jsonDict = [self dictionaryFromJSON:JSON];
    NSArray *values = [jsonDict allValues];
    NSArray *keys = [jsonDict allKeys];
    
    for (int i = 0; i < [keys count]; i++) {
        NSString *key = keys[i];
        id value = values[i];
        
        SEL propertySelector = NSSelectorFromString(key);
        if ([newObject respondsToSelector:propertySelector]) {
            if ([value isKindOfClass:[NSDictionary class]]) {
                NSString *classType = [self findClassType:newObject forKey:key];
                Class class = NSClassFromString(classType);
                if (class == [NSDictionary class]) {
                    [newObject setValue:value forKeyPath:key];
                } else {
                    [newObject setValue:[self dictionaryToObject:value forClass:classType] forKey:key];
                }
            } else if ([value isKindOfClass:[NSArray class]]) {
                NSString *name = [self findPropertyName:newObject forKey:key];
                NSString *class = [self findClassType:newObject forKey:key];
                NSMutableArray *muteArray = [NSMutableArray new];
                for (NSDictionary *obj in value) {
                    id nested = [self dictionaryToObject:obj forClass:NSStringFromClass([iSON arrayTypeForPropertyName:name])];
                    [muteArray addObject:nested];
                }
                if (NSClassFromString(class) == [NSMutableArray class]) {
                    [newObject setValue:muteArray forKey:key];
                } else {
                    [newObject setValue:[NSArray arrayWithArray:muteArray] forKey:key];
                }
            } else {
                if ([value isKindOfClass:[NSNumber class]]) {
                    [newObject setValue:value forKey:key];
                } else {
                    NSDate *date = [self dateFromString:value];
                    [newObject setValue:(date ? date : value) forKey:key];
                }
            }
        }
    }
    return newObject;
}

- (id)dictionaryToObject:(NSDictionary *)JSON forClass:(NSString *)className
{
    id nestedObject = [NSClassFromString(className) new];
    
    NSString *jsonString = [self jsonToString:JSON];
    NSDictionary *jsonDict = [self dictionaryFromJSON:jsonString];
    NSArray *values = [jsonDict allValues];
    NSArray *keys = [jsonDict allKeys];
    
    for (int i = 0; i < [keys count]; i++) {
        NSString *key = keys[i];
        id value = values[i];
        
        SEL propertySelector = NSSelectorFromString(key);
        if ([nestedObject respondsToSelector:propertySelector]) {
            if ([value isKindOfClass:[NSDictionary class]]) {
                NSString *className = [self findClassType:nestedObject forKey:key];
                [nestedObject setValue:[self dictionaryToObject:value forClass:className] forKey:key];
            } else if ([value isKindOfClass:[NSArray class]]) {
                NSString *name = [self findPropertyName:nestedObject forKey:key];
                NSString *class = [self findClassType:nestedObject forKey:key];
                NSMutableArray *muteArray = [NSMutableArray new];
                for (NSDictionary *obj in value) {
                    id nested = [self dictionaryToObject:obj forClass:NSStringFromClass([iSON arrayTypeForPropertyName:name])];
                    [muteArray addObject:nested];
                }
                if (NSClassFromString(class) == [NSMutableArray class]) {
                    [nestedObject setValue:muteArray forKey:key];
                } else {
                    [nestedObject setValue:[NSArray arrayWithArray:muteArray] forKey:key];
                }
            } else {
                if ([value isKindOfClass:[NSNumber class]]) {
                    [nestedObject setValue:value forKey:key];
                } else {
                    NSDate *date = [self dateFromString:value];
                    [nestedObject setValue:(date ? date : value) forKey:key];
                }
            }
        }
    }
    return nestedObject;
}

#pragma mark -
#pragma mark - Helpers
- (NSDictionary *)dictionaryFromJSON:(NSString *)JSON
{
    NSData *webData = [JSON dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    return [NSJSONSerialization JSONObjectWithData:webData options:NSJSONReadingMutableContainers error:&error];
}

- (NSArray *)arrayFromJSON:(NSString *)JSON
{
    NSData *webData = [JSON dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    return [NSJSONSerialization JSONObjectWithData:webData options:NSJSONReadingMutableContainers error:&error];
}

- (NSString *)findPropertyName:(id)object forKey:(NSString *)key
{
    objc_property_t prop = class_getProperty([object class], [key UTF8String]);
    const char *propertyName = property_getName(prop);
    return [NSString stringWithUTF8String:propertyName];
}

- (NSString *)findClassType:(id)object forKey:(NSString *)key
{
    objc_property_t prop = class_getProperty([object class], [key UTF8String]);
    const char * propertyAttrs = property_getAttributes(prop);
    return [self findClassName:[NSString stringWithUTF8String:propertyAttrs]];
}

- (NSString *)findClassName:(NSString *)message
{
    NSRange startRange = [message rangeOfString:@"@\""];
    NSRange endRange = [message rangeOfString:@"\",&"];
    NSRange searchRange = NSMakeRange(startRange.location, endRange.location);
    searchRange.length -= endRange.length;
    searchRange.location += startRange.length;
    return [message substringWithRange:searchRange];
}

- (NSString *)jsonToString:(NSDictionary *)JSON
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:JSON options:NSJSONWritingPrettyPrinted error:&error];
    
    if (!jsonData) {
        NSLog(@"Got an error: %@", error);
        return nil;
    }
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (NSString *)formatDate:(NSDate *)date
{
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mmZ"];
    }
    return [dateFormatter stringFromDate:date];
}

- (NSDate *)dateFromString:(NSString *)date
{
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mmZ"];
    }
    return [dateFormatter dateFromString:date];
}

@end
