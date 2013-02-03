//
//  SCCSVWriter.m
//  SCStringsUtility
//
//  Created by Stefan Ceriu on 10/14/12.
//  Copyright (c) 2012 Stefan Ceriu. All rights reserved.
//

#import "SCCSVWriter.h"

@interface SCCSVWriter ()
@property (nonatomic, retain) NSFileHandle *fileHandle;
@property (nonatomic, retain) NSString *separator;
@property (nonatomic, retain) NSArray *headers;
@end

@implementation SCCSVWriter
@synthesize fileHandle;
@synthesize separator;
@synthesize headers;

- (id)initWithHeaders:(NSArray*)heads filePath:(NSString*)path separator:(NSString*)sep
{
    if(self = [super init])
    {
        [[NSFileManager defaultManager] createFileAtPath:path contents:[NSData data] attributes:nil];
        self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:path];
        if(fileHandle == nil) {SCLog(@"Unable to open file for writing at path %@", path); return nil;}
        
        self.separator = sep;
        self.headers = heads;
        
        [self appendRow:headers];
    }
    
    return self;
}

- (void)appendRow:(NSArray*)components
{
    if(components.count != self.headers.count)
    {
        SCLog(@"Number of components doesn't match the number of headers");
        return;
    }
        
    [self.fileHandle writeData:[[components componentsJoinedByString:self.separator] dataUsingEncoding:NSUTF8StringEncoding]];
    [self.fileHandle writeData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)dealloc
{
    [self.fileHandle closeFile];
}

@end
