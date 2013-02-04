//
//  NSString+SCAdditions.m
//  SCStringsUtility
//
//  Created by Stefan Ceriu on 10/14/12.
//  Copyright (c) 2012 Stefan Ceriu. All rights reserved.
//

#import "NSString+SCAdditions.h"

@implementation NSString (SCAdditions)

//http://stackoverflow.com/a/2166853
- (NSUInteger)numberOfOccurrencesOfString:(NSString *)needle
{
    const char * rawNeedle = [needle UTF8String];
    NSUInteger needleLength = strlen(rawNeedle);
    
    const char * rawHaystack = [self UTF8String];
    NSUInteger haystackLength = strlen(rawHaystack);
    
    NSUInteger needleCount = 0;
    NSUInteger needleIndex = 0;
    for (NSUInteger index = 0; index < haystackLength; ++index) {
        const char thisCharacter = rawHaystack[index];
        if (thisCharacter != rawNeedle[needleIndex]) {
            needleIndex = 0;
        }
        
        if (thisCharacter == rawNeedle[needleIndex]) {
            needleIndex++;
            if (needleIndex >= needleLength) {
                needleCount++;
                needleIndex = 0;
            }
        }
    }
    
    return needleCount;
}

- (NSString*)stringByTrimmingLeadingWhiteSpaces
{
    NSRange range = [self rangeOfString:@"^\\s*" options:NSRegularExpressionSearch];
    return [self stringByReplacingCharactersInRange:range withString:@""];
}

- (NSString*)stringByTrimmingTralingWhiteSpaces
{
    NSRange range = [self rangeOfString:@"\\s*$" options:NSRegularExpressionSearch];
    return [self stringByReplacingCharactersInRange:range withString:@""];
}

@end
