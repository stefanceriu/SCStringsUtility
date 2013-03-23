//
//  CSVReader.m
//  CSVWriter
//
//  Created by Stefan Ceriu on 10/11/12.
//
//

#import "SCReader.h"
#import "NSString+SCAdditions.h"
#import "NSData+SCAdditions.h"

@interface SCReader ()
{    
    NSFileHandle * fileHandle;
    unsigned long long currentOffset;
    unsigned long long totalFileLength;
    
    NSString * lineDelimiter;    
    BOOL commentStarted;
}

@property (nonatomic) NSUInteger chunkSize;
@property (nonatomic, strong) NSString *filePath;

@end

@implementation SCReader
@synthesize filePath;
@synthesize currentLine;
@synthesize chunkSize;
@synthesize encoding;

- (id)initWithPath:(NSString*)path
{
    if(self = [super init])
    {
        self.filePath = path;

        fileHandle = [NSFileHandle fileHandleForReadingAtPath:self.filePath];
        if (fileHandle == nil) return nil;
        
        NSError *error;
        if (![NSString detectFileEncoding:&encoding path:filePath error:&error]) {
            // fallback
            encoding = NSUTF8StringEncoding;
        }
                
        lineDelimiter = @"\n";
        filePath = path;
        currentOffset = 0ULL;
        chunkSize = 10;
        [fileHandle seekToEndOfFile];
        totalFileLength = [fileHandle offsetInFile];
    }
    
    return self;
}

- (NSString *)readLine
{
    if (currentOffset >= totalFileLength) { currentOffset = 0ULL; currentLine = 0; return nil; }

    NSData * newLineData = [lineDelimiter dataUsingEncoding:self.encoding];
    [fileHandle seekToFileOffset:currentOffset];
    NSMutableData * currentData = [[NSMutableData alloc] init];
    BOOL shouldReadMore = YES;
    
    @autoreleasepool {
        
        while (shouldReadMore) {
            if (currentOffset >= totalFileLength) { break; }
            NSData * chunk = [fileHandle readDataOfLength:chunkSize];
            NSRange newLineRange = [chunk rangeOfData_dd:newLineData];
            if (newLineRange.location != NSNotFound) {
                
                //include the length so we can include the delimiter in the string
                chunk = [chunk subdataWithRange:NSMakeRange(0, newLineRange.location+[newLineData length])];
                shouldReadMore = NO;
            }
            [currentData appendData:chunk];
            currentOffset += [chunk length];
        }
    }
    
    currentLine ++;

    NSString * line = [[NSString alloc] initWithData:currentData encoding:self.encoding];
    return line;
}

- (NSString *) readTrimmedLine
{
    return [[self readLine] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

#if NS_BLOCKS_AVAILABLE
- (void)enumerateLinesUsingBlock:(void(^)(NSString*, BOOL*))block
{
    NSString * line = nil;
    BOOL stop = NO;
    while (stop == NO && (line = [self readLine])) {
        block(line, &stop);
    }
}
#endif

- (NSString*)translationForKey:(NSString*)someKey
{
    NSString *comment = nil;
    NSString *key = nil;
    NSString *translation = nil;
    
    while([self getNextComment:&comment key:&key translation:&translation])
    {
        if([key isEqualToString:someKey]) return translation;
    }
    return nil;
}

- (BOOL) getNextComment:(NSString**)comment key:(NSString**)key translation:(NSString**)translation
{
    *comment        = @"";
    *key            = nil;
    *translation    = nil;
    
    NSString *tempString = @"";
    while ((tempString = [self readTrimmedLine]))
    {
        if([tempString rangeOfString:@"/*"].location != NSNotFound)
        {
            *comment = [*comment stringByAppendingString:tempString];
            commentStarted = YES;
            continue;
        }
        else if([tempString rangeOfString:@"*/"].location != NSNotFound && commentStarted)
        {
            tempString = [@"\\n" stringByAppendingString:tempString];
            *comment = [*comment stringByAppendingString:tempString];
            commentStarted = NO;
            continue;
        }
        else if([tempString rangeOfString:@"="].location != NSNotFound)
        {
            NSArray *components = [tempString componentsSeparatedByString:@"="];
            *key = [components[0] stringByTrimmingTralingWhiteSpaces];
            *key = [*key substringWithRange:NSMakeRange(1, [*key length]-2)];
            
            *translation = [components[1] stringByTrimmingLeadingWhiteSpaces];
            *translation = [*translation substringWithRange:NSMakeRange(1, [*translation length] - 3)];
            break;
        }
        else if([tempString length] && commentStarted)
        {
            tempString = [@"\\n" stringByAppendingString:tempString];
            *comment = [*comment stringByAppendingString:tempString];
        }
    }
        
    if(!*key) return NO;

    *key = [*key stringByReplacingOccurrencesOfString:@"\\\"" withString:@"'"];
    *translation = [*translation stringByReplacingOccurrencesOfString:@"\\\"" withString:@"'"];
    
    return YES;
}

- (void) dealloc
{
    [fileHandle closeFile];
    fileHandle = nil;
    filePath = nil;
    lineDelimiter = nil;
    currentOffset = 0ULL;
}

@end
