//
//  CMPreferencesController.m
//  CopyMate
//
//  Created by hewig on 12/6/13.
//  Copyright (c) 2013 kernelpanic.im. All rights reserved.
//

#import "Constants.h"
#import "CMPreferencesController.h"
#import "MASShortcutView.h"
#import "MASShortcutView+UserDefaults.h"


@interface CMPreferencesController ()

@property (weak, nonatomic) IBOutlet NSToolbar* toolbar;
@property (weak, nonatomic) IBOutlet MASShortcutView* appendCopyshortcutView;
@property (weak, nonatomic) IBOutlet MASShortcutView* defaultFormatShortcutView;
@property (weak, nonatomic) IBOutlet MASShortcutView* alterFormatShortcutView;

@end

@implementation CMPreferencesController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    //[self.toolbar ins]
}

@end
