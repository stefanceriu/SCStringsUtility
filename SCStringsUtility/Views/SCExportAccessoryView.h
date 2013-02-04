//
//  SCExportAccessoryView.h
//  SCStringsUtility
//
//  Created by Stefan Ceriu on 2/4/13.
//  Copyright (c) 2013 Stefan Ceriu. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol SCExportAccessoryViewDelegate;

@interface SCExportAccessoryView : NSView

@property (nonatomic, assign) id<SCExportAccessoryViewDelegate> delegate;

- (BOOL)shouldIncludeComments;
- (BOOL)shouldUseKeyForMissingTranslations;

- (void)setSelectedExportType:(SCFileType)type;
- (SCFileType)selectedExportType;

@end

@protocol SCExportAccessoryViewDelegate <NSObject>

@optional
- (void)exportAccessoryView:(SCExportAccessoryView*)view didSelectFormatType:(SCFileType)type;

@end
