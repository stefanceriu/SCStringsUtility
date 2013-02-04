//
//  SCStringsWriter.h
//  CSVWriter
//
//  Created by Stefan Ceriu on 10/11/12.
//
//

@interface SCStringsWriter : NSObject

- (id)initWithHeaders:(NSArray*)headers;
- (void)writeTranslations:(NSDictionary*)translations toPath:(NSString*)path failure:(void(^)(NSError *error))failure;

- (id)initWithTranslationFiles:(NSDictionary *)files;
- (void)writeTranslations:(NSDictionary*)translations failure:(void(^)(NSError *error))failure;;

@end
