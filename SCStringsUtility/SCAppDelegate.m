//
//  SCAppDelegate.m
//  SCStringsUtility
//
//  Created by Stefan Ceriu on 10/12/12.
//  Copyright (c) 2012 Stefan Ceriu. All rights reserved.
//

#import "SCAppDelegate.h"
#import "NSString+SCAdditions.h"

@implementation SCAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self.window setContentView:self.rootViewController.view];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return self.rootViewController.undoManager;
}

@end
