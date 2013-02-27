//
//  SCStringsWriter.m
//  CSVWriter
//
//  Created by Stefan Ceriu on 10/11/12.
//
//

#import "SCStringsWriter.h"
#import "SCReader.h"
#import "NSString+SCAdditions.h"

@interface SCStringsWriter ()
@property (nonatomic, strong) NSMutableDictionary *fileHandlers;
@property (nonatomic, strong) NSArray *headers;
@property(nonatomic, assign) NSStringEncoding fileEncoding;
@end

@implementation SCStringsWriter
@synthesize fileHandlers;
@synthesize headers;
@synthesize fileEncoding;

- (id)initWithHeaders:(NSArray *)heads
{
    if(self = [super init])
    {
        self.headers = heads;
    }
    
    return self;
}

- (id)initWithTranslationFiles:(NSDictionary *)files
{
    if(self = [super init])
    {
        self.fileHandlers = [NSMutableDictionary dictionary];
        
        NSMutableArray *heads = [NSMutableArray array];
        for(NSString *key in files)
        {
            for(NSDictionary *x in [files objectForKey:key])
            {
                NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:[x objectForKey:@"Path"]];
                if(fileHandle == nil) {SCLog(@"Unable to open file for writing at path %@", [x objectForKey:@"Path"]); return nil;}

                if (![NSString detectFileEncoding:&fileEncoding path:[x objectForKey:@"Path"] error:nil]) {
                    // fallback
                    fileEncoding = NSUTF8StringEncoding;
                }
                
                [self.fileHandlers setObject:fileHandle forKey:[x objectForKey:@"Language"]];
                [heads addObject:[x objectForKey:@"Language"]];
            }
        }
        self.headers = heads;
    }
    
    return self;
}

- (void)writeTranslations:(NSDictionary*)translations failure:(void(^)(NSError *error))failure
{
    for(NSString *key in translations)
    {
        NSDictionary *translationDict = [translations objectForKey:key];
        
        if([[translationDict objectForKey:@"Comment"] length])
        {
            NSString *comment = [NSString stringWithFormat:@"%@\n", [[translationDict objectForKey:@"Comment"] stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"]];
            for(NSString *fileHandleKey in self.fileHandlers)
                [(NSFileHandle*)[self.fileHandlers objectForKey:fileHandleKey] writeData:[comment dataUsingEncoding:self.fileEncoding]];
        }
        
        for(NSString *header in self.headers)
        {
            NSString *translation = [translationDict objectForKey:header];
            if(!translation.length) translation = key;
            
            NSString *line = [NSString stringWithFormat:@"\"%@\" = \"%@\";\n\n", key, translation];
            [(NSFileHandle*)[self.fileHandlers objectForKey:header] writeData:[line dataUsingEncoding:self.fileEncoding]];
        }
    }
    
    for(NSString *fileHandleKey in self.fileHandlers)
        [(NSFileHandle*)[self.fileHandlers objectForKey:fileHandleKey] closeFile];
}

- (void)writeTranslations:(NSDictionary*)translations toPath:(NSString*)path failure:(void(^)(NSError *error))failure
{
    self.fileHandlers = [NSMutableDictionary dictionary];
    
    NSError *error;
    for(NSString *x in headers)
    {
        NSString *languageIdentifier = [NSLocale canonicalLanguageIdentifierFromString:x];
        
        NSString *lprojPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.lproj", languageIdentifier]];
        [[NSFileManager defaultManager] createDirectoryAtPath:lprojPath withIntermediateDirectories:YES attributes:nil error:&error];
        if(error) {
            if(failure) failure(error);
            return;
        }
        
        NSString *stringsPath = [lprojPath stringByAppendingPathComponent:@"Localizable.strings"];
        [[NSFileManager defaultManager] createFileAtPath:stringsPath contents:[NSData data] attributes:nil];
        
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:stringsPath];
        if(fileHandle == nil) SCLog(@"Unable to open file for writing at path %@", stringsPath);
        
        [self.fileHandlers setObject:fileHandle forKey:x];
    }
    
    [self writeTranslations:translations failure:failure];
}

@end
