//
//  NSString+SCAdditions.h
//  SCStringsUtility
//
//  Created by Stefan Ceriu on 10/14/12.
//  Copyright (c) 2012 Stefan Ceriu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (SCAdditions)

- (NSUInteger)numberOfOccurrencesOfString:(NSString *)cursor;

- (NSString*)stringByTrimmingLeadingWhiteSpaces;
- (NSString*)stringByTrimmingTralingWhiteSpaces;

+ (BOOL)detectFileEncoding:(NSStringEncoding *)encoding path:(NSString *)path error:(NSError **)error;

@end
