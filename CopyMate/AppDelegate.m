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

void *CMUserDefaultsContext = &CMUserDefaultsContext;

@interface AppDelegate()

@property (strong, nonatomic) NSStatusItem* statusItem;
@property (strong, nonatomic) CMPreferencesController* prefController;
@property (strong, nonatomic) NSMutableDictionary* prefsDict;
@property (weak, nonatomic) NSString* currentFormat;
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

- (void)applicationWillTerminate:(NSNotification *)notification{
    [self persistDefaults];
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
    [self.prefController displayWindow];
}

-(void)quitApp{
    NSLog(@"==> quitApp");
    [[NSApplication sharedApplication] terminate:self];
}

#pragma mark KVO
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    NSLog(@"==> keyPath:%@ changed to:%@",keyPath, change);
    
    if ([keyPath isEqualToString:CopyMateStartAtLogin]) {
        if ([change[@"new"] integerValue] == 0) {
            NSLog(@"==> disable auto start");
            [self removeLoginItem];
        } else{
            NSLog(@"==> enable auto start");
            [self addLoginItem];
        }
        [self persistDefaults];
    }
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
    [statusMenu addItemWithTitle:@"Quit" action:@selector(quitApp) keyEquivalent:@"q"];
    self.statusItem.menu = statusMenu;
}

-(void)setupPreferences
{
    self.prefController = [[CMPreferencesController alloc] initWithWindowNibName:@"CMPreferencesController"];
    self.prefsDict = [[self.defaults persistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]] mutableCopy];
    
    if (![self.defaults objectForKey:CopyMateNotFirstRun]) {
        self.prefsDict[CopyMateDefaultFormat] = @"%@\n%@";
        self.currentFormat = self.prefsDict[CopyMateDefaultFormat];
        
        self.prefsDict[CopyMateAlterFormat] = @"%@ %@";
        self.currentFormat = self.prefsDict[CopyMateAlterFormat];
        
        self.prefsDict[CopyMateAutoCheckUpdate] = @YES;
        self.prefsDict[CopyMateStartAtLogin] = @YES;
        
        self.prefsDict[CopyMateNotFirstRun] = @YES;
        
        [self persistDefaults];
    }
    
    for (id key in self.prefsDict){
        [self.prefsDict addObserver:self forKeyPath:[key description]
                            options:NSKeyValueObservingOptionNew context:(__bridge void *)(key)];
    }

    self.prefController.prefsDict = self.prefsDict;
}

-(void)persistDefaults
{
    [self.defaults setPersistentDomain:self.prefsDict forName:[[NSBundle mainBundle] bundleIdentifier]];
}

-(void)registerShortcuts
{
    void(^copyHandler)(void) = ^{
        [self copyAppendImpl];
    };
    
    void(^defaultFormatHandler)(void) = ^{
        self.currentFormat = self.prefsDict[CopyMateDefaultFormat];
    };
    
    void(^alterFormatHandler)(void) = ^{
        self.currentFormat = self.prefsDict[CopyMateAlterFormat];
    };
    
    [self registerShortcut:MASPrefKeyCopyShortcut Keycode:kVK_ANSI_C Handler:copyHandler];
    [self registerShortcut:MASPrefKeyDefaultFormatShortcut Keycode:kVK_ANSI_1 Handler:defaultFormatHandler];
    [self registerShortcut:MASPrefKeyAlterFormatShortcut Keycode:kVK_ANSI_2 Handler:alterFormatHandler];
}

-(void)copyAppendImpl
{
    NSString* lastCopyString = [[NSPasteboard generalPasteboard] stringForType:NSStringPboardType];
    
    QCUIElement *focusedElement = [QCUIElement focusedElement];
    QCUIElement *sourceApplicationElement = [focusedElement application];
    NSString *editString = [sourceApplicationElement readString];
    
    if (editString) {
        NSString* appendString = [NSString stringWithFormat:self.currentFormat, lastCopyString, editString];
        NSLog(@"appendString is %@", appendString);
        
        [[NSPasteboard generalPasteboard] clearContents];
        [[NSPasteboard generalPasteboard] writeObjects:@[appendString]];
    }
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

-(void)removeLoginItem{
    [self loginItemAction:NO];
}

-(void)addLoginItem{
    [self loginItemAction:YES];
}

-(void)loginItemAction:(BOOL) enable{
    BOOL found = NO;
    CFURLRef appPathURL = (__bridge CFURLRef)([[NSBundle mainBundle] bundleURL]);
    
    LSSharedFileListRef loginItemsRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    CFArrayRef loginItems = LSSharedFileListCopySnapshot(loginItemsRef, NULL);
    LSSharedFileListItemRef appItem = NULL;
    for (CFIndex i=0, count = CFArrayGetCount(loginItems); i<count ; i++)
    {
        LSSharedFileListItemRef item = (LSSharedFileListItemRef)CFArrayGetValueAtIndex(loginItems, i);
        UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
        CFURLRef currentItemURL = NULL;
        LSSharedFileListItemResolve(item, resolutionFlags, &currentItemURL, NULL);
        if(currentItemURL)
        {
            if (CFEqual(currentItemURL, appPathURL))
            {
                found = YES;
                appItem = item;
                CFRelease(currentItemURL);
                break;
            }
            CFRelease(currentItemURL);
        }
    }
    
    if(found && !enable){
        LSSharedFileListItemRemove(loginItemsRef, appItem);
    } else if (!found && enable){
        LSSharedFileListInsertItemURL(loginItemsRef, kLSSharedFileListItemBeforeFirst,
                                      NULL, NULL, (CFURLRef)appPathURL, NULL, NULL);
    }
    
    CFRelease(loginItems);
    CFRelease(loginItemsRef);
}

@end
