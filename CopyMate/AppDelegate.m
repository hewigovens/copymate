//
//  AppDelegate.m
//  CopyMate
//
//  Created by hewig on 12/6/13.
//  Copyright (c) 2013 kernelpanic.im. All rights reserved.
//

#import "AppDelegate.h"
#import "Constants.h"
#import "CMPreferencesController.h"

#import "QuickCursor/QCUIElement.h"

#import "MASShortcut.h"
#import "MASShortcut+UserDefaults.h"
#import "MASShortcut+Monitoring.h"

@interface AppDelegate()

@property (strong, nonatomic) NSStatusItem* statusItem;
@property (strong, nonatomic) CMPreferencesController* prefController;
@property (weak, nonatomic) NSString* currentFormat;
@property (strong, nonatomic) NSString* defaultFormat;
@property (strong, nonatomic) NSString* alterFormat;
@property (readonly, nonatomic) NSPasteboard* pasteboard;
@property (readonly, nonatomic) NSUserDefaults* defaults;

@end

@implementation AppDelegate

#pragma mark NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self setupStatusItem];
    [self setupPreferences];
    [self registerShortcuts];
}

#pragma mark properties

-(NSPasteboard*)pasteboard
{
    return [NSPasteboard generalPasteboard];
}

-(NSUserDefaults*)defaults{
    return [NSUserDefaults standardUserDefaults];
}

#pragma mark Menu Actions

-(void)copyAppend{
    NSLog(@"==> copyAppend");
    [self copyAppendImpl];
}

-(void)openPreferences{
    NSLog(@"==> openPreferences");
    [self.prefController showWindow:nil];
}

-(void)quitApp{
    NSLog(@"==> quitApp");
    [[NSApplication sharedApplication] terminate:self];
}

#pragma mark helper

-(void)setupStatusItem
{
    NSStatusBar* statusBar = [NSStatusBar systemStatusBar];
    self.statusItem = [statusBar statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.image = [NSImage imageNamed:@"statusMenu"];
    self.statusItem.highlightMode = YES;
    NSMenu* statusMenu = [[NSMenu alloc] initWithTitle:@"CopyMate"];
    [statusMenu addItemWithTitle:@"Copy" action:@selector(copyAppend) keyEquivalent:@""];
    [statusMenu addItem:[NSMenuItem separatorItem]];
    [statusMenu addItemWithTitle:@"Preferences..." action:@selector(openPreferences) keyEquivalent:@","];
    [statusMenu addItem:[NSMenuItem separatorItem]];
    [statusMenu addItemWithTitle:@"Quit" action:@selector(quitApp) keyEquivalent:@""];
    self.statusItem.menu = statusMenu;
}

-(void)setupPreferences
{
    self.prefController = [[CMPreferencesController alloc] initWithWindowNibName:@"CMPreferencesController"];
    self.defaultFormat = [self.defaults objectForKey:CopyMateDefaultFormat];
    if (!self.defaultFormat) {
        self.defaultFormat = @"%@\n%@";
    }
    
    self.alterFormat = [self.defaults objectForKey:CopyMateAlterFormat];
    if (!self.alterFormat) {
        self.alterFormat = @"%@ %@";
    }
    
    self.currentFormat = self.defaultFormat;
}

-(void)registerShortcuts
{
    void(^copyHandler)(void) = ^{
        [self copyAppendImpl];
    };
    
    void(^defaultFormatHandler)(void) = ^{
        self.currentFormat = self.defaultFormat;
    };
    
    void(^alterFormatHandler)(void) = ^{
        self.currentFormat = self.alterFormat;
    };
    
    [self registerShortcut:MASPrefKeyCopyShortcut Keycode:kVK_ANSI_C Handler:copyHandler];
    [self registerShortcut:MASPrefKeyDefaultFormatShortcut Keycode:kVK_ANSI_1 Handler:defaultFormatHandler];
    [self registerShortcut:MASPrefKeyAlterFormatShortcut Keycode:kVK_ANSI_2 Handler:alterFormatHandler];
}

-(void)copyAppendImpl
{
    NSString* lastCopyString = [[NSPasteboard generalPasteboard] stringForType:NSStringPboardType];
    NSLog(@"lastCopyString is %@", lastCopyString);
    
    QCUIElement *focusedElement = [QCUIElement focusedElement];
    QCUIElement *sourceApplicationElement = [focusedElement application];
    NSString *editString = [sourceApplicationElement readString];
    NSLog(@"editString is %@", editString);
    
    NSString* appendString = [NSString stringWithFormat:self.currentFormat, lastCopyString, editString];
    NSLog(@"appendString is %@", appendString);
    
    [[NSPasteboard generalPasteboard] clearContents];
    [[NSPasteboard generalPasteboard] writeObjects:@[appendString]];
}

-(void)registerShortcut:(NSString*) defaultsKey
                Keycode:(NSUInteger) defaultKeyCode
                Handler:(void(^)(void)) handler
{
    if ([self.defaults objectForKey:defaultsKey]) {
        [MASShortcut registerGlobalShortcutWithUserDefaultsKey:MASPrefKeyCopyShortcut handler:handler];
    } else{
        MASShortcut* shortcut = [MASShortcut shortcutWithKeyCode:defaultKeyCode modifierFlags:NSControlKeyMask|NSShiftKeyMask];
        [MASShortcut addGlobalHotkeyMonitorWithShortcut:shortcut handler:handler];
    }
}

@end
