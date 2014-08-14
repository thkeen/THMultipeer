//
//  NSData+Helpers.m
//  Num
//
//  Created by BuUuKeen on 14/8/14.
//  Copyright (c) 2014 Thkeen. All rights reserved.
//

#import "NSData+Helpers.h"

@implementation NSData (Helpers)

+ (NSData *)dataWithDictionary:(NSDictionary *)dictionary {
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:dictionary forKey:@"dictionary"];
    [archiver finishEncoding];
    return data;
}
+ (NSDictionary *)dictionaryFromData:(NSData *)data {
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    NSDictionary *dictionary = [unarchiver decodeObjectForKey:@"dictionary"];
    [unarchiver finishDecoding];
    return dictionary;
}

@end

