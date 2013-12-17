//
//  SCRootViewController.m
//  SCStringsUtility
//
//  Created by Stefan Ceriu on 10/12/12.
//  Copyright (c) 2012 Stefan Ceriu. All rights reserved.
//

#import "SCRootViewController.h"
#import "SCStringsController.h"

#import "SCOpenAccessoryView.h"
#import "SCExportAccessoryView.h"

static NSString *kFileTypeXcodeProject = @"xcodeproj";
static NSString *kFileTypeCSV = @"csv";
static NSString *kFileTypeXML = @"xml";

@interface SCRootViewController () <NSSplitViewDelegate, NSTextDelegate, SCStringsControllerDelegate>

@property (nonatomic, weak) IBOutlet NSSplitView *splitView;

@property (nonatomic, weak) IBOutlet NSOutlineView *outlineView;
@property (nonatomic, weak) IBOutlet NSTableView *tableView;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *progressIndicator;

@property (nonatomic, weak) IBOutlet NSButton *saveButton;
@property (nonatomic, weak) IBOutlet NSButton *exportButton;

@property (nonatomic, weak) IBOutlet NSSearchField *searchField;
@property (nonatomic, weak) IBOutlet NSButton *searchKeysOnlyCheckboxButton;

@property (nonatomic, assign) IBOutlet NSTextView *textView;

@property (nonatomic, weak) IBOutlet SCOpenAccessoryView *openPanelAccessoryView;
@property (nonatomic, weak) IBOutlet SCExportAccessoryView *exportPanelAccessoryView;

@property (nonatomic, strong) __block NSSavePanel *exportPanel;

@property (nonatomic, strong) SCStringsController *stringsController;

@property (nonatomic, assign) SCFileType selectedFileType;

@end

@implementation SCRootViewController

- (NSUndoManager *)undoManager
{
    return self.stringsController.undoManager;
}

- (void)loadView
{
    [super loadView];
    
    self.stringsController = [[SCStringsController alloc] init];
    [self.stringsController setDelegate:self];
    
    [self.outlineView setDataSource:self.stringsController];
    [self.outlineView setDelegate:self.stringsController];
    
    [self.tableView setDataSource:self.stringsController];
    [self.tableView setDelegate:self.stringsController];
    
    [self.stringsController setOutlineView:self.outlineView];
    [self.stringsController setTableView:self.tableView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResize:) name:NSWindowDidEndLiveResizeNotification object:nil];
}

- (void)reset
{
    [self.stringsController reset];
    self.textView.string = @"";
}

- (void)reloadData
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.outlineView reloadData];
        [self.outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
        [self.outlineView expandItem:nil expandChildren:YES];
        
        [self.progressIndicator stopAnimation:self];
        [self.progressIndicator.animator    setAlphaValue:0.0f];
        [self.saveButton.animator           setAlphaValue:1.0f];
        [self.exportButton.animator         setAlphaValue:1.0f];
    });
}

#pragma mark - Actions

- (IBAction)onExportClick:(id)sender
{
    if(!self.exportPanel)
    {
        switch (self.stringsController.sourceType)
        {
            case SCFileTypeXcodeProject:
            {
                [self.exportPanelAccessoryView setSelectedExportType:SCFileTypeCSV];
                break;
            }
            case SCFileTypeCSV:
            {
                [self.exportPanelAccessoryView setSelectedExportType:SCFileTypeXcodeProject];
                break;
            }
            case SCFileTypeXML:
            {
                [self.exportPanelAccessoryView setSelectedExportType:SCFileTypeXcodeProject];
                break;
            }
            default:
            {
                [self.exportPanelAccessoryView setSelectedExportType:SCFileTypeCSV];
                break;
            }
        }
    }
    else {
        
        [self.exportPanel setCanCreateDirectories:YES];
        [self.exportPanel setAccessoryView:self.exportPanelAccessoryView];
        
        [self.exportPanel beginWithCompletionHandler:^(NSInteger result) {
            
            if(result != NSOKButton) return;
            
            switch ([self.exportPanelAccessoryView selectedExportType])
            {
                case SCFileTypeXcodeProject:
                {
                    [self.stringsController generateStringFilesAtPath:[[self.exportPanel URL] path]
                                                              success:nil
                                                              failure:nil];
                    
                    break;
                }
                case SCFileTypeCSV:
                {
                    BOOL includeComments = [self.exportPanelAccessoryView shouldIncludeComments];
                    BOOL useKeyForMissingTranslations = [self.exportPanelAccessoryView shouldUseKeyForMissingTranslations];
                    
                    [self.stringsController generateCSVAtPath:[[self.exportPanel URL] path]
                                              includeComments:includeComments
                                   useKeyForEmptyTranslations:useKeyForMissingTranslations
                                                      success:nil
                                                      failure:nil];
                    
                    break;
                }
                case SCFileTypeXML:
                {
                    BOOL includeComments = [self.exportPanelAccessoryView shouldIncludeComments];
                    BOOL useKeyForMissingTranslations = [self.exportPanelAccessoryView shouldUseKeyForMissingTranslations];
                    
                    [self.stringsController generateXMLFileAtPath:[[self.exportPanel URL] path]
                                                  includeComments:includeComments
                                       useKeyForEmptyTranslations:useKeyForMissingTranslations
                                                          success:nil
                                                          failure:nil];
                    break;
                }
                default:
                {
                    break;
                }
            }
        }];
    }
}

- (void)exportAccessoryView:(SCExportAccessoryView*)view didSelectFormatType:(SCFileType)type
{
    switch (type) {
        case SCFileTypeXcodeProject:
        {
            [self.exportPanel close];
            
            self.exportPanel = [NSOpenPanel openPanel];
            [(NSOpenPanel*)self.exportPanel setCanChooseFiles:NO];
            [(NSOpenPanel*)self.exportPanel setCanChooseDirectories:YES];
            
            break;
        }
        default:
        {
            BOOL shouldReload = !self.exportPanel || [self.exportPanel isKindOfClass:[NSOpenPanel class]];
            
            if(shouldReload)
            {
                [self.exportPanel close];
                
                self.exportPanel = [NSSavePanel savePanel];
                [self.exportPanel setCanCreateDirectories:YES];
            }
            
            [self.exportPanel setAllowedFileTypes:(type == SCFileTypeXML ? @[@"xml"] : @[@"csv"])];
            
            break;
        }
    }
    
    if(!self.exportPanel.isVisible)
        [self onExportClick:nil];
}

- (IBAction)onSaveClick:(id)sender
{
    [self.stringsController save:nil failure:^(NSError *error) {
        SCLog(@"Could not save data %@", error);
    }];
}

- (IBAction)onOpenClick:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setDelegate:(id <NSOpenSavePanelDelegate>)self];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setCanCreateDirectories:NO];
    [openPanel setAllowsMultipleSelection:NO];
    
    [openPanel setAllowedFileTypes:@[@"xcodeproj", @"csv", @"xml"]];
    
    NSInteger result = [openPanel runModal];
    if(result != NSOKButton) return;
    
    [self.progressIndicator.animator    setAlphaValue:1.0f];
    [self.progressIndicator             startAnimation:self];
    
    [self reset];
    
    switch (self.selectedFileType) {
        case SCFileTypeXcodeProject:
        {
            if(!openPanel.accessoryView) {
                SCLog(@"Unkown error");
                return;
            }
            
            BOOL includePositionalParameters = [self.openPanelAccessoryView shouldAddPositionalParameters];
            NSString *routine = [self.openPanelAccessoryView genstringsRoutine];
            NSString *stringsFile = [self.openPanelAccessoryView stringsFileName];
            
            [self.stringsController importProjectAtPath:[[openPanel URL] path]
                                   positionalParameters:includePositionalParameters
                                      genstringsRoutine:routine
                                        stringsFileName:stringsFile
                                                success:^{ [self reloadData];}
                                                failure:^(NSError *error) { SCLog(@"Could not import Xcode project %@", error);}];
            break;
        }
        case SCFileTypeCSV:
        {
            [self.stringsController importCSVFileAtPath:[[openPanel URL] path]
                                                success:^{ [self reloadData];}
                                                failure:^(NSError *error) { SCLog(@"Could not import CSV file %@",error);}];
            break;
        }
        case SCFileTypeXML:
        {
            [self.stringsController importXMLFileAtPath:[[openPanel URL] path]
                                                success:^{ [self reloadData]; }
                                                failure:^(NSError *error) { SCLog(@"Could not import XML file %@",error);}];
        }
        default:
        {
            break;
        }
    }
    
    self.selectedFileType = SCFileTypeInvalid;
}

- (void)panelSelectionDidChange:(NSOpenPanel*)sender
{
    static NSDictionary *extensionToType;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        extensionToType = (@{kFileTypeXcodeProject : @(SCFileTypeXcodeProject),
                           kFileTypeCSV : @(SCFileTypeCSV),
                           kFileTypeXML : @(SCFileTypeXML)
                           });
    });
    
    NSString *extension = [[sender.URL path] pathExtension];
    
    if(extension.length == 0) return;
    
    SCFileType selectedType = [extensionToType[extension] intValue];
    switch (selectedType) {
        case SCFileTypeXcodeProject:
        {
            [sender setAccessoryView:self.openPanelAccessoryView];
            break;
        }
        case SCFileTypeCSV:
        {
            [sender setAccessoryView:nil];
            break;
        }
        case SCFileTypeXML:
        {
            [sender setAccessoryView:nil];
            break;
        }
        default:
        {
            break;
        }
    }
    
    self.selectedFileType = selectedType;
}

typedef enum {
    SearchViewModeClosed,
    SearchViewModeOpened
} SearchViewMode;

- (IBAction)triggerSearchField:(id)sender
{
    CGRect frame = self.splitView.frame;
    switch (self.searchField.tag)
    {
        case SearchViewModeClosed:
        {
            [self.searchField setTag:SearchViewModeOpened];
            [self.searchField.animator setAlphaValue:1.0f];
            [self.searchField becomeFirstResponder];
            
            frame.size.height -= self.searchField.frame.size.height + 5.0f;
            break;
        }
        case SearchViewModeOpened:
        {
            [self.searchField setTag:SearchViewModeClosed];
            [self.searchField.animator setAlphaValue:0.0f];
            [[[NSApplication sharedApplication] keyWindow] makeFirstResponder:nil];
            
            frame.size.height += self.searchField.frame.size.height + 5.0f;
            break;
        }
    }
    
    [self.splitView.animator setFrame:frame];
}

#pragma mark - Filtering

- (void)filterEntries
{
    BOOL searchOnlyKeys = self.searchKeysOnlyCheckboxButton.state;
    NSString *searchString = [self.searchField.stringValue lowercaseString];
    
    [self.stringsController filterEntriesWithSearchString:searchString onlyKeys:searchOnlyKeys];
    [self.tableView reloadData];
}

- (void)controlTextDidChange:(NSNotification *)notification {
    if(![notification.object isEqual:self.searchField]) {
        return;
    }
    
    [self filterEntries];
}

- (IBAction)onSearchKeysOnlyCheckboxButtonValueChanged:(id)sender {
    [self filterEntries];
}

#pragma mark - NSSplitViewDelegate

- (void)splitView:(NSSplitView *)splitView resizeSubviewsWithOldSize:(NSSize)oldSize
{
    CGFloat dividerThickness = [splitView dividerThickness];
    NSRect leftRect  = [[[splitView subviews] objectAtIndex:0] frame];
    NSRect rightRect = [[[splitView subviews] objectAtIndex:1] frame];
    NSRect newFrame  = [splitView frame];
    
    leftRect.size.height = newFrame.size.height;
    leftRect.origin = NSMakePoint(0, 0);
    rightRect.size.width = newFrame.size.width - leftRect.size.width - dividerThickness;
    rightRect.size.height = newFrame.size.height ;
    rightRect.origin.x = leftRect.size.width + dividerThickness;
    
    [[[splitView subviews] objectAtIndex:0] setFrame:leftRect];
    [[[splitView subviews] objectAtIndex:1] setFrame:rightRect];
}

#pragma mark - SCStringsControllerDelegate

- (void)stringsController:(SCStringsController *)stringsController didGetGenstringsOutput:(NSString *)output
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.textView.string = [self.textView.string stringByAppendingString:output];
        [self.textView scrollToEndOfDocument:nil];
    });
}

#pragma mark - Properties

- (SCOpenAccessoryView *)openPanelAccessoryView
{
    if(!_openPanelAccessoryView)
    {
        Class class = [SCOpenAccessoryView class];
        
        NSArray *items;
        
        NSNib *nib = [[NSNib alloc] initWithNibNamed:NSStringFromClass(class) bundle:nil];
        [nib instantiateNibWithOwner:self topLevelObjects:&items];
        
        [items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if([obj isKindOfClass:class])
            {
                _openPanelAccessoryView = obj;
                stop = YES;
            }
            
        }];
        
    }
    
    return _openPanelAccessoryView;
}

- (SCExportAccessoryView *)exportPanelAccessoryView
{
    if(!_exportPanelAccessoryView)
    {
        Class class = [SCExportAccessoryView class];
        
        NSArray *items;
        
        NSNib *nib = [[NSNib alloc] initWithNibNamed:NSStringFromClass(class) bundle:nil];
        [nib instantiateNibWithOwner:nil topLevelObjects:&items];
        
        [items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if([obj isKindOfClass:class])
            {
                _exportPanelAccessoryView = obj;
                [_exportPanelAccessoryView setDelegate:(id<SCExportAccessoryViewDelegate>)self];
                stop = YES;
            }
        }];
    }
    
    return _exportPanelAccessoryView;
}

#pragma mark - Others

- (void)windowDidResize:(NSNotification *)notification
{
    [self.tableView reloadData];
}

typedef enum
{
    SCMenuItemOpenProject = 1,
    SCMenuItemImport,
    SCMenuItemSave,
    SCMenuItemExport,
    SCMenuItemFind
} SCMenuItem;

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    switch (menuItem.tag)
    {
        case SCMenuItemOpenProject:
        {
            return YES;
        }
        case SCMenuItemImport:
        {
            return YES;
        }
        case SCMenuItemSave:
        {
            return (self.stringsController.sourceType != SCFileTypeInvalid);
        }
        case SCMenuItemExport:
        {
            return (self.stringsController.sourceType != SCFileTypeInvalid);
        }
        case SCMenuItemFind:
        {
            return YES;
        }
    }
    
    return YES;
}

@end