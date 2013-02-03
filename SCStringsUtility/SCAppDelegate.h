//
//  SCAppDelegate.h
//  SCStringsUtility
//
//  Created by Stefan Ceriu on 10/12/12.
//  Copyright (c) 2012 Stefan Ceriu. All rights reserved.
//

#import "SCRootViewController.h"

@interface SCAppDelegate : NSObject <NSApplicationDelegate, NSOpenSavePanelDelegate, NSWindowDelegate>

@property (nonatomic, assign) IBOutlet NSWindow *window;
@property (nonatomic, strong) IBOutlet NSMenu *menu;
@property (nonatomic, strong) IBOutlet SCRootViewController *rootViewController;

@end
