//  iSON
//
//  Created by Adam Fisch on 8/28/13.
//  Copyright (c) 2013 Adam Fisch. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface iSON : NSObject

+ (void)registerObjectByPropertyName:(NSString *)propertyName forClass:(Class)cls;
+ (Class)arrayTypeForPropertyName:(NSString *)propertyName;
+ (NSString *)objectToJSON:(id)object;
+ (NSArray *)objectFromUnnamedArrayJSON:(NSString *)JSON forClass:(Class)cls;
+ (NSString *)arrayToJSON:(NSArray *)items;
+ (id)objectFromJSON:(NSString *)JSON forClass:(Class)className;
+ (void)setDateFormatter:(NSString *)dateFormat;
+ (NSString *)dictionaryToJSON:(NSDictionary *)dict;

@end
