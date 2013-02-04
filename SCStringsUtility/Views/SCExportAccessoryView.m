//
//  SCExportAccessoryView.m
//  SCStringsUtility
//
//  Created by Stefan Ceriu on 2/4/13.
//  Copyright (c) 2013 Stefan Ceriu. All rights reserved.
//

#import "SCExportAccessoryView.h"

@interface SCExportAccessoryView () <NSComboBoxDelegate>
@property (nonatomic, weak) IBOutlet NSButton *includeCommentsButton;
@property (nonatomic, weak) IBOutlet NSButton *useKeyForMissingTranslationsButton;
@property (nonatomic, weak) IBOutlet NSComboBox *formatComboBox;
@end

@implementation SCExportAccessoryView

- (BOOL)shouldIncludeComments
{
    return [self.includeCommentsButton state];
}

- (BOOL)shouldUseKeyForMissingTranslations
{
    return [self.useKeyForMissingTranslationsButton state];
}

- (void)setSelectedExportType:(SCFileType)type
{
    [self.formatComboBox selectItemAtIndex:type-1];
}

- (SCFileType)selectedExportType
{
    return (SCFileType)self.formatComboBox.indexOfSelectedItem + 1;
}

- (void)comboBoxSelectionDidChange:(NSNotification *)notification
{
    if([self.delegate respondsToSelector:@selector(exportAccessoryView:didSelectFormatType:)])
        [self.delegate exportAccessoryView:self didSelectFormatType:[self selectedExportType]];
}

@end
