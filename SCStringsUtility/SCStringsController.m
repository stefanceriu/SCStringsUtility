//
//  SCStringsDataSource.m
//  SCStringsUtility
//
//  Created by Stefan Ceriu on 2/2/13.
//  Copyright (c) 2013 Stefan Ceriu. All rights reserved.
//

#import "SCStringsController.h"
#import "SCReader.h"
#import "NSString+SCAdditions.h"
#import "SCCSVWriter.h"
#import "SCStringsWriter.h"
#import "OrderedDictionary.h"

#import <XcodeEditor/XCProject.h>
#import <XcodeEditor/XCSourceFile.h>
#import <XcodeEditor/XCGroup.h>

static NSString *kKey = @"Key";
static NSString *kKeyPath = @"Path";

static NSString *kKeyComment = @"Comment";
static NSString *kKeyImported = @"Imported";
static NSString *kKeyLanguage = @"Language";
static NSString *kKeyLocalizable = @"Localizable";
static NSString *kKeyStringsFile = @"Localizable.strings";

@interface SCStringsController ()

@property (nonatomic, strong) XCProject *project;
@property (nonatomic, strong) NSString *sourceFilePath;

@property (nonatomic, assign) SCFileType sourceType;

@property (nonatomic, strong) NSMutableDictionary *translationFiles;
@property (nonatomic, strong) OrderedDictionary *filteredTranslationsDictionary;
@property (nonatomic, strong) OrderedDictionary *translationsDictionary;

@end

@implementation SCStringsController

- (id)init
{
    if(self = [super init])
    {
        self.undoManager = [[NSUndoManager alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(outlineViewSelectionDidChange:) name:NSOutlineViewSelectionDidChangeNotification object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reset
{
    self.translationsDictionary = [OrderedDictionary dictionary];
    self.translationFiles = [NSMutableDictionary dictionary];
    self.sourceType = SCFileTypeInvalid;
    
    [self.outlineView reloadData];
    
    NSTableColumn* column = [[self.tableView tableColumns] lastObject];
    while (column)
    {
        [self.tableView removeTableColumn:column];
        column = [[self.tableView tableColumns] lastObject];
    }
}

- (void)save:(void (^)(void))success failure:(void (^)(NSError *error))failure
{
    switch (self.sourceType) {
        case SCFileTypeInvalid:
        {
            return;
        }
        case SCFileTypeXcodeProject:
        {
            [self generateStringFilesAtPath:nil success:success failure:failure];
            break;
        }
        case SCFileTypeCSV:
        {
            [self generateCSVAtPath:nil includeComments:YES useKeyForEmptyTranslations:NO success:success failure:failure];
            break;
        }
        case SCFileTypeXML:
        {
            [self generateXMLFileAtPath:nil includeComments:YES useKeyForEmptyTranslations:NO success:success failure:failure];
            break;
        }
    }
}

#pragma mark - Importers

- (void)importCSVFileAtPath:(NSString *)path success:(void (^)(void))success failure:(void (^)(NSError *))failure
{
    self.sourceFilePath = path;
    self.project = nil;
    self.sourceType = SCFileTypeCSV;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        SCReader * reader = [[SCReader alloc] initWithPath:self.sourceFilePath];
        
        NSArray *headers = [[reader readTrimmedLine] componentsSeparatedByString:@","];
        headers = [headers subarrayWithRange:NSMakeRange(1, headers.count-1)];
        
        self.translationFiles = [NSMutableDictionary dictionaryWithObject:[NSMutableArray array] forKey:kKeyImported];
        for(NSString *header in headers)
        {
            if([header isEqualToString:kKeyComment]) continue;
            
            [[self.translationFiles objectForKey:kKeyImported] addObject:[NSDictionary dictionaryWithObject:header forKey:kKeyLanguage]];
        }
        
        self.translationsDictionary = [OrderedDictionary dictionary];
        
        [reader enumerateLinesUsingBlock:^(NSString * line, BOOL * stop) {
            line = [line stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            
            NSArray *components = [line componentsSeparatedByString:@","];
            if([line rangeOfString:@"\""].location != NSNotFound) //line contains a comma
            {
                NSMutableArray *mutableComponents = [components mutableCopy];
                
                BOOL commaPresent = YES;
                
                //Try merging together components from the same string
                while(commaPresent)
                {
                    commaPresent = NO;
                    
                    for(int i=0;i<mutableComponents.count;i++)
                    {
                        NSString *x = [mutableComponents objectAtIndex:i];
                        if([x numberOfOccurrencesOfString:@"\""] % 2)
                        {
                            commaPresent = YES;
                            [mutableComponents replaceObjectAtIndex:i+1 withObject:[[mutableComponents objectAtIndex:i] stringByAppendingFormat:@",%@",[mutableComponents objectAtIndex:i+1]]];
                            [mutableComponents removeObjectAtIndex:i];
                            break;
                        }
                    }
                }
                components = [NSArray arrayWithArray:mutableComponents];
            }
            
            NSString *key = [components objectAtIndex:0];
            if([key rangeOfString:@"\""].location == 0)
                key = [key substringWithRange:NSMakeRange(1, key.length-2)];
            
            if(![self.translationFiles objectForKey:key])
                [self.translationsDictionary setObject:[NSMutableDictionary dictionary] forKey:key];
            
            for(int i=0; i<headers.count; i++)
            {
                NSString *component = [components objectAtIndex:i+1];
                
                if([component rangeOfString:@"\""].location == 0)
                    component = [component substringWithRange:NSMakeRange(1, component.length-2)];
                
                if([component length])
                {
                    [[self.translationsDictionary objectForKey:key] setObject:component forKey:[headers objectAtIndex:i]];
                }
                else
                {
                    //[[self.translationsDict objectForKey:key] setObject:key forKey:[headers objectAtIndex:i]];
                }
            }
        }];
        
        [self setFilteredTranslationsDictionary:[self.translationsDictionary mutableCopy]];
        
        if(success) dispatch_async(dispatch_get_main_queue(), success);
    });
}

- (void)importProjectAtPath:(NSString *)path
       positionalParameters:(BOOL)includePositionalParameters
          genstringsRoutine:(NSString *)genstringsRoutine
            stringsFileName:(NSString*)stringsFileName
                    success:(void (^)(void))success
                    failure:(void (^)(NSError *))failure
{
    self.project = [[XCProject alloc] initWithFilePath:path];
    self.sourceFilePath = nil;
    self.sourceType = SCFileTypeXcodeProject;
    
    if (stringsFileName.length == 0) {
        stringsFileName = kKeyStringsFile;
    } else if(stringsFileName.pathExtension.length == 0) {
        stringsFileName = [stringsFileName stringByAppendingPathExtension:kKeyStringsFile.pathExtension];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSArray *files = [self.project.files filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(XCSourceFile *evaluatedObject, NSDictionary *bindings) {
            return [[evaluatedObject.name lastPathComponent] isEqualToString:stringsFileName];
        }]];
        
        for(XCSourceFile *file in files)
        {
            NSString *language = [[[file.name stringByDeletingLastPathComponent] lastPathComponent] stringByDeletingPathExtension];
            if(!language) continue;
            
            XCGroup *parentGroup = [[self.project groupForGroupMemberWithKey:file.key] parentGroup];
            
            NSString *categoryName = [[parentGroup displayName] stringByAppendingPathComponent:[stringsFileName stringByDeletingPathExtension]];
            if(![self.translationFiles objectForKey:categoryName])
                [self.translationFiles setObject:[NSMutableArray array] forKey:categoryName];
            
            NSMutableArray *fileParent = [self.translationFiles objectForKey:categoryName];
            [fileParent addObject:@{ kKeyPath : [[self.project.filePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:[file pathRelativeToProjectRoot]], kKeyLanguage : language}];
            
            NSSortDescriptor *sortByLanguage = [NSSortDescriptor sortDescriptorWithKey:kKeyLanguage ascending:YES];
            [fileParent sortUsingDescriptors:@[sortByLanguage]];
        }
        
        NSString *stringsFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:stringsFileName];
        [[NSFileManager defaultManager] removeItemAtPath:stringsFilePath error:nil];
        
        [self executeGenStringsAtPath:[self.project.filePath stringByDeletingLastPathComponent] withRoutine:genstringsRoutine positionalParameters:includePositionalParameters];
        
        SCReader *genstringsOutputReader = [[SCReader alloc] initWithPath:stringsFilePath];
        NSString *comment, *key, *translation;
        while([genstringsOutputReader getNextComment:&comment key:&key translation:&translation]) {
            [self.translationsDictionary setObject:[NSMutableDictionary dictionaryWithObject:comment forKey:kKeyComment] forKey:key];
        }
        
        [self setFilteredTranslationsDictionary:[self.translationsDictionary mutableCopy]];
        
        if(success) dispatch_async(dispatch_get_main_queue(), success);
    });
}

-(void)executeGenStringsAtPath:(NSString*)path withRoutine:(NSString*)routine positionalParameters:(BOOL)positionalParameters
{
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/sh"];
    [task setCurrentDirectoryPath:path];
    
    NSMutableString *argumentsString = [NSMutableString stringWithString:@"find ./ \\( -name *.m -o -name *.swift \\) -exec genstrings -a"];
    
    if([routine length]) {
        [argumentsString appendString:[NSString stringWithFormat:@" -s %@", routine]];
    }
    
    if(!positionalParameters) {
        [argumentsString appendString:@" -noPositionalParameters"];
    }
    
    [argumentsString appendFormat:@" -o %@ {} \\;", NSTemporaryDirectory()];
    
    [task setArguments:@[@"-c", argumentsString]];
    
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    [task setStandardError: pipe];
    
    [task launch];
    
    while ([task isRunning])
    {
        if([self.delegate respondsToSelector:@selector(stringsController:didGetGenstringsOutput:)])
            [self.delegate stringsController:self didGetGenstringsOutput:[[NSString alloc] initWithData:[[pipe fileHandleForReading] readDataToEndOfFile] encoding: NSUTF8StringEncoding]];
    }
}

- (void)importXMLFileAtPath:(NSString*)path
                    success:(void (^)(void))success
                    failure:(void(^)(NSError *error))failure
{
    self.project = nil;
    self.sourceFilePath = path;
    self.sourceType = SCFileTypeXML;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        NSInputStream *stream = [[NSInputStream alloc] initWithFileAtPath:path];
        [stream open];
        
        NSError *error;
        NSPropertyListFormat format;
        NSDictionary *translations = [NSPropertyListSerialization propertyListWithStream:stream options:NSPropertyListMutableContainersAndLeaves format:&format error:&error];
        
        [stream close];
        
        if(error || format != NSPropertyListXMLFormat_v1_0) {
            SCLog(@"Unexpected XML format");
            if(failure) failure(error);
            
            [self reset];
            return;
        }
        
        self.translationFiles = nil;
        self.translationsDictionary = [OrderedDictionary dictionary];
        [translations enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *obj, BOOL *stop) {
            
            if(!self.translationFiles) {
                self.translationFiles = [NSMutableDictionary dictionaryWithObject:[NSMutableArray array] forKey:kKeyImported];
            }
            
            for(NSString *language in [obj allKeys]) {
                if([language isEqualToString:kKeyComment]) continue;
                if([[self.translationFiles objectForKey:kKeyImported] containsObject:@{kKeyLanguage : language}]) continue;
                
                [[self.translationFiles objectForKey:kKeyImported] addObject:@{kKeyLanguage : language}];
            }
            
            [self.translationsDictionary setObject:obj forKey:key];
        }];
        
        [self setFilteredTranslationsDictionary:[self.translationsDictionary mutableCopy]];
        
        if(success) dispatch_async(dispatch_get_main_queue(), success);
    });
}

#pragma mark - Exporters

- (void)generateStringFilesAtPath:(NSString *)path success:(void (^)(void))success failure:(void (^)(NSError *))failure
{
    if(path)
    {
        NSMutableArray *headers = [NSMutableArray array];
        for(NSTableColumn *column in self.tableView.tableColumns)
        {
            if([column.identifier isEqualToString:kKey]) continue;
            if([column.identifier isEqualToString:kKeyComment]) continue;
            
            [headers addObject:column.identifier];
        }
        
        SCStringsWriter *stringsWriter = [[SCStringsWriter alloc] initWithHeaders:headers];
        [stringsWriter writeTranslations:self.translationsDictionary toPath:path failure:^(NSError *error) {
            SCLog(@"Could not write string files %@", error);
            if(failure) failure(error);
            return;
        }];
    }
    else {
        SCStringsWriter *stringsWriter = [[SCStringsWriter alloc] initWithTranslationFiles:self.translationFiles];
        [stringsWriter writeTranslations:self.translationsDictionary failure:^(NSError *error) {
            SCLog(@"Could not write string files %@", error);
            if(failure) failure(error);
            return;
        }];
    }
}

- (void)generateCSVAtPath:(NSString *)path
          includeComments:(BOOL)includeComments
useKeyForEmptyTranslations:(BOOL)useKeyForEmptyTranslations
                  success:(void (^)(void))success
                  failure:(void (^)(NSError *))failure
{
    NSMutableArray *headers = [NSMutableArray array];
    for(NSTableColumn *column in self.tableView.tableColumns)
    {
        if(!includeComments && [column.identifier isEqualToString:kKeyComment]) continue;
        [headers addObject:column.identifier];
    }
    
    SCCSVWriter *writer = [[SCCSVWriter alloc] initWithHeaders:headers filePath:path ? path : self.sourceFilePath separator:@","];
    
    for(NSString *key in self.translationsDictionary)
    {
        NSMutableArray *row = [NSMutableArray arrayWithObject:[NSString stringWithFormat:@"\"%@\"", key]];
        for(int i=1; i < headers.count; i++)
        {
            NSString *translation = [[self.translationsDictionary objectForKey:key] objectForKey:[headers objectAtIndex:i]];
            if(![translation length] || [translation isEqualToString:key]) translation = useKeyForEmptyTranslations ? key : @"";//key;
            [row addObject:[NSString stringWithFormat:@"\"%@\"",translation]];
        }
        [writer appendRow:row];
    }
    
    if(success) dispatch_async(dispatch_get_main_queue(), success);
}

- (void)generateXMLFileAtPath:(NSString*)path
              includeComments:(BOOL)includeComments
   useKeyForEmptyTranslations:(BOOL)useKeyForEmptyTranslations
                      success:(void (^)(void))success
                      failure:(void (^)(NSError *error))failure
{
    NSMutableArray *headers = [NSMutableArray array];
    for(NSTableColumn *column in self.tableView.tableColumns)
    {
        if(!includeComments && [column.identifier isEqualToString:kKeyComment]) continue;
        [headers addObject:column.identifier];
    }
    
    OrderedDictionary *results = [self.translationsDictionary mutableCopy];
    
    [results enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSMutableDictionary* obj, BOOL *stop) {
        
        if(!includeComments)
            [obj removeObjectForKey:kKeyComment];
        
        [headers enumerateObjectsUsingBlock:^(id header, NSUInteger idx, BOOL *stop) {
            if(useKeyForEmptyTranslations && ((NSString*)[obj objectForKey:header]).length == 0)
                [obj setObject:key forKey:header];
        }];
    }];
    
    
    NSError *error;
    [[NSPropertyListSerialization dataWithPropertyList:results format:NSPropertyListXMLFormat_v1_0 options:0 error:&error] writeToFile:path ? path : self.sourceFilePath atomically:YES];
    
    if(error) {
        SCLog(@"%@", error);
        if(failure) failure(error);
    }
    else {
        if(success) success();
    }
}


#pragma mark - Filtering

- (void)filterEntriesWithSearchString:(NSString *)searchString onlyKeys:(BOOL)searchOnlyKeys
{
    //[self.undoManager removeAllActions];//TODO:
    
    self.filteredTranslationsDictionary = [self.translationsDictionary mutableCopy];
    
    if(searchString.length > 0)
    {
        [self.translationsDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            
            __block BOOL souldKeepLine = NO;
            
            if([[key lowercaseString] rangeOfString:searchString].location != NSNotFound)
            {
                souldKeepLine = YES;
            }
            
            if(!searchOnlyKeys)
            {
                [obj enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    
                    if([[obj lowercaseString] rangeOfString:searchString].location != NSNotFound)
                    {
                        souldKeepLine = YES;
                    }
                }];
            }
            
            if(!souldKeepLine)
                [self.filteredTranslationsDictionary removeObjectForKey:key];
        }];
    }
}

#pragma mark - NSOutlineView DataSource&Delegate

- (void)outlineViewSelectionDidChange:(NSNotification*)sender
{
    if(![sender.object isEqual:self.outlineView]) return;
    
    if(self.outlineView.selectedRow == -1) return;
    
    id selectedItem = [self.outlineView itemAtRow:self.outlineView.selectedRow];
    
    NSTableColumn* column = [[self.tableView tableColumns] lastObject];
    while (column)
    {
        [self.tableView removeTableColumn:column];
        column = [[self.tableView tableColumns] lastObject];
    }
    
    column = [[NSTableColumn alloc] initWithIdentifier:kKey];
    [[column headerCell] setStringValue:kKey];
    [self.tableView addTableColumn:column];
    
    if([selectedItem isKindOfClass:[NSArray class]])
    {
        column = [[NSTableColumn alloc] initWithIdentifier:kKeyComment];
        [[column headerCell] setStringValue:kKeyComment];
        [self.tableView addTableColumn:column];
        
        for(NSDictionary *dict in selectedItem)
        {
            column = [[NSTableColumn alloc] initWithIdentifier:[dict objectForKey:kKeyLanguage]];
            [[column headerCell] setStringValue:[dict objectForKey:kKeyLanguage]];
            [self.tableView addTableColumn:column];
            
            SCReader *reader = [[SCReader alloc] initWithPath:[dict objectForKey:kKeyPath]];
            NSString *comment, *key, *translation;
            while ([reader getNextComment:&comment key:&key translation:&translation]) {
                [[self.translationsDictionary objectForKey:key] setObject:translation forKey:column.identifier];
            }
        }
    }
    else
    {
        column = [[NSTableColumn alloc] initWithIdentifier:[selectedItem objectForKey:kKeyLanguage]];
        [[column headerCell] setStringValue:[selectedItem objectForKey:kKeyLanguage]];
        [self.tableView addTableColumn:column];
        
        SCReader *reader = [[SCReader alloc] initWithPath:[selectedItem objectForKey:kKeyPath]];
        
        NSString *comment, *key, *translation;
        while ([reader getNextComment:&comment key:&key translation:&translation]) {
            [[self.translationsDictionary objectForKey:key] setObject:translation forKey:column.identifier];
        }
    }
    
    for(NSTableColumn *column in self.tableView.tableColumns)
        [column setWidth:self.tableView.bounds.size.width/self.tableView.tableColumns.count];
    
    [self.tableView reloadData];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    return (item == nil) ? self.translationFiles.allKeys.count : [item count];
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return [item isKindOfClass:[NSArray class]];
}


- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if(item == nil)
    {
        NSString *key = [self.translationFiles.allKeys objectAtIndex:index];
        return [self.translationFiles objectForKey:key];
    }
    
    return [item objectAtIndex:index];
}


- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if([item isKindOfClass:[NSArray class]])
        return [[self.translationFiles allKeysForObject:item] lastObject];
    else
        return [item objectForKey:kKeyLanguage];
}



#pragma mark - NSTableView DataSource&Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.filteredTranslationsDictionary.allKeys.count;
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(NSTextFieldCell*)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    [cell setWraps:YES];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSString *key = [self.filteredTranslationsDictionary keyAtIndex:row];
    
    if([tableColumn.identifier isEqualToString:kKey])
        return key;
    else
        return [[self.filteredTranslationsDictionary objectForKey:key] objectForKey:tableColumn.identifier];
}

- (CGFloat)tableView:(NSTableView *)aTableView heightOfRow:(NSInteger)row
{
    NSString *rootKey = [self.filteredTranslationsDictionary keyAtIndex:row];
    NSTableColumn *tableColoumn = [aTableView tableColumnWithIdentifier:kKey];
    
    CGFloat rowHeight = 5;
    if (tableColoumn)
    {
        NSRect myRect = NSMakeRect(0, 0, [tableColoumn width], CGFLOAT_MAX);
        NSCell *dataCell = [tableColoumn dataCell];
        [dataCell setWraps:YES];
        
        [dataCell setStringValue:rootKey];
        rowHeight = MAX(rowHeight, [dataCell cellSizeForBounds:myRect].height);
        
        for(NSString *key in [[self.filteredTranslationsDictionary objectForKey:rootKey] allKeys])
        {
            [dataCell setStringValue:[[self.filteredTranslationsDictionary objectForKey:rootKey] objectForKey:key]];
            rowHeight = MAX(rowHeight, [dataCell cellSizeForBounds:myRect].height);
        }
    }
    return rowHeight;
}

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if([tableColumn.identifier isEqualToString:kKey]) return NO;
    return YES;
}

- (void)tableView:(NSTableView *)someTableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSString *key = [self.filteredTranslationsDictionary keyAtIndex:row];
    
    NSString *translation = [[self.translationsDictionary objectForKey:key] objectForKey:tableColumn.identifier];
    if(!translation) translation = @"";
    [[self.undoManager prepareWithInvocationTarget:self] tableView:someTableView setObjectValue:translation forTableColumn:tableColumn row:row];
    
    [[self.translationsDictionary objectForKey:key] setObject:object forKey:tableColumn.identifier];
    [someTableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row] columnIndexes:[NSIndexSet indexSetWithIndex:[someTableView.tableColumns indexOfObject:tableColumn]]];
}

@end
