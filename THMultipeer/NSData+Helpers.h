//
//  NSData+Helpers.h
//  Num
//
//  Created by BuUuKeen on 14/8/14.
//  Copyright (c) 2014 Thkeen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (Helpers)
+ (NSData*)dataWithDictionary:(NSDictionary*)dictionary;
+ (NSDictionary*)dictionaryFromData:(NSData*)data;
@end
