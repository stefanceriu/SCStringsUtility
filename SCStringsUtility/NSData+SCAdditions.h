//
//  NSData+SCAdditions.h
//  SCStringsUtility
//
//  Created by Stefan Ceriu on 10/26/12.
//  Copyright (c) 2012 Stefan Ceriu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (SCAdditions)
- (NSRange) rangeOfData_dd:(NSData *)dataToFind;
@end