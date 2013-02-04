//
//  SCCSVWriter.h
//  SCStringsUtility
//
//  Created by Stefan Ceriu on 10/14/12.
//  Copyright (c) 2012 Stefan Ceriu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCCSVWriter : NSObject

- (id)initWithHeaders:(NSArray*)heads filePath:(NSString*)path separator:(NSString*)sep;
- (void)appendRow:(NSArray*)components;

@end
