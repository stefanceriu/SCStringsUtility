//
//  CSVReader.h
//  CSVWriter
//
//  Created by Stefan Ceriu on 10/11/12.
//
//

#import <Foundation/Foundation.h>

@interface SCReader : NSObject

@property (nonatomic, assign, readonly) NSUInteger currentLine;
@property (nonatomic, assign, readonly) NSStringEncoding encoding;

- (id)initWithPath:(NSString*)path;

- (NSString *) readLine;
- (NSString *) readTrimmedLine;
- (void) enumerateLinesUsingBlock:(void(^)(NSString*, BOOL*))block;

- (NSString*)translationForKey:(NSString*)key;
- (BOOL) getNextComment:(NSString**)comment key:(NSString**)key translation:(NSString**)translation;

@end
