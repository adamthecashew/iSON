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
+ (id)objectFromJSON:(NSString *)JSON forClass:(Class)className;
@end
