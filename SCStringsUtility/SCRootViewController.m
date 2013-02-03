//
//  SCRootViewController.m
//  SCStringsUtility
//
//  Created by Stefan Ceriu on 10/12/12.
//  Copyright (c) 2012 Stefan Ceriu. All rights reserved.
//

#import "SCRootViewController.h"
#import "SCStringsController.h"

@interface SCRootViewController () <NSSplitViewDelegate, NSTextDelegate, SCStringsControllerDelegate>

@property (nonatomic, weak) IBOutlet NSSplitView *splitView;

@property (nonatomic, weak) IBOutlet NSOutlineView *outlineView;
@property (nonatomic, weak) IBOutlet NSTableView *tableView;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *progressIndicator;

@property (nonatomic, weak) IBOutlet NSButton *saveButton;
@property (nonatomic, weak) IBOutlet NSButton *exportButton;

@property (nonatomic, weak) IBOutlet NSView *openProjectPanelAccessoryView;
@property (nonatomic, weak) IBOutlet NSView *saveToCSVPanelAccessoryView;

@property (nonatomic, weak) IBOutlet NSSearchField *searchField;
@property (nonatomic, weak) IBOutlet NSButton *searchKeysOnlyCheckboxButton;

@property (nonatomic, assign) IBOutlet NSTextView *textView;
@property (nonatomic, strong) SCStringsController *stringsController;

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
    if(self.stringsController.sourceType == SCSourceTypeInvalid) return;
    
    if(self.stringsController.sourceType == SCSourceTypeXcodeProject) {
        NSSavePanel *savePanel = [NSSavePanel savePanel];
        [savePanel setCanCreateDirectories:YES];
        [savePanel setAllowedFileTypes:@[@"csv"]];
        [savePanel setAccessoryView:self.saveToCSVPanelAccessoryView];
        
        if([savePanel runModal] != NSOKButton) return;
        
        BOOL includeComments = ((NSButton*)[self.saveToCSVPanelAccessoryView.subviews objectAtIndex:0]).state;
        BOOL useKeyForEmptyTranslations = ((NSButton*)[self.saveToCSVPanelAccessoryView.subviews objectAtIndex:1]).state;
        
        [self.stringsController generateCSVAtPath:[[savePanel URL] path] includeComments:includeComments useKeyForEmptyTranslations:useKeyForEmptyTranslations success:^{
            
        } failure:^(NSError *error) {
            NSLog(@"Could not generate CSV file %@", error);
        }];
    }
    else {
        
        NSOpenPanel *openPanel = [NSOpenPanel openPanel];
        [openPanel setCanChooseDirectories:YES];
        [openPanel setCanChooseFiles:NO];
        [openPanel setCanCreateDirectories:YES];
        [openPanel setAllowsMultipleSelection:NO];
        
        if([openPanel runModal] != NSOKButton) return;
        
        [self.stringsController generateStringFilesAtPath:[[openPanel URL] path] success:^{
            
        } failure:^(NSError *error) {
            NSLog(@"Could not generate string files %@", error);
        }];
    }
    
}

- (IBAction)onSaveClick:(id)sender
{
    if(self.stringsController.sourceType == SCSourceTypeInvalid) return;
    
    if(self.stringsController.sourceType == SCSourceTypeXcodeProject) {
        [self.stringsController generateStringFilesAtPath:nil success:^{
            
        } failure:^(NSError *error) {
            NSLog(@"Could not generate string files %@", error);
        }];
    }
    else {
        [self.stringsController generateCSVAtPath:nil includeComments:YES useKeyForEmptyTranslations:NO success:^{
            
        } failure:^(NSError *error) {
            NSLog(@"Could not generate CSV file %@", error);
        }];
    }
}

- (IBAction)onOpenProjectClick:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setCanCreateDirectories:NO];
    [openPanel setAllowsMultipleSelection:NO];
    
    [openPanel setAllowedFileTypes:@[@"xcodeproj"]];
    
    [openPanel setAccessoryView:self.openProjectPanelAccessoryView];
    
    NSInteger result = [openPanel runModal];
    if(result != NSOKButton) return;
    
    [self.progressIndicator.animator    setAlphaValue:1.0f];
    [self.progressIndicator             startAnimation:self];
    
    [self reset];
    
    BOOL includePositionalParamters = ((NSButton*)[self.openProjectPanelAccessoryView.subviews objectAtIndex:0]).state;
    
    NSString *routine = ((NSTextField*)[self.openProjectPanelAccessoryView.subviews lastObject]).stringValue;
    if(![routine length]) routine = nil;
    
    [self.stringsController importProjectAtPath:[[openPanel URL] path]
                           positionalParameters:includePositionalParamters
                              genstringsRoutine:routine success:^{ [self reloadData];}
                                        failure:^(NSError *error) { NSLog(@"Could not import Xcode project %@", error);}];
}

- (IBAction)onImportClick:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setCanCreateDirectories:NO];
    [openPanel setAllowsMultipleSelection:NO];
    
    [openPanel setAllowedFileTypes:@[@"csv"]];
    
    NSInteger result = [openPanel runModal];
    if(result != NSOKButton) return;
    
    [self.progressIndicator    setAlphaValue:1.0f];
    [self.progressIndicator    startAnimation:self];
    
    [self reset];
    
    [self.stringsController importCSVFileAtPath:[[openPanel URL] path] success:^{
        [self reloadData];
    } failure:^(NSError *error) {
        NSLog(@"Could not import CSV file %@",error);
    }];
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
            return (self.stringsController.sourceType != SCSourceTypeInvalid);
        }
        case SCMenuItemExport:
        {
            return (self.stringsController.sourceType != SCSourceTypeInvalid);
        }
        case SCMenuItemFind:
        {
            return YES;
        }
    }
    
    return YES;
}

@end