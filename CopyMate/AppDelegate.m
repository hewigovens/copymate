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

#import <Sparkle/Sparkle.h>

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
#ifndef DEBUG
    NSString* logPath = [NSString stringWithFormat:@"%@/Library/Logs/CopyMate.log", NSHomeDirectory()];
    freopen([logPath fileSystemRepresentation], "a+", stderr);
#endif
    [self setupStatusItem];
    [self setupPreferences];
    [self registerShortcuts];
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
}

- (void)applicationWillTerminate:(NSNotification *)notification{
    [self persistDefaults];
}

#pragma mark NSUserNotificationCenterDelegate

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    //always show banner
    return YES;
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
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDefaultsDidChange:) name:NSUserDefaultsDidChangeNotification object:self.defaults];
    });
}

-(void)checkForUpdates:(id)sender{
    NSLog(@"==> checkForUpdates");
    [[SUUpdater sharedUpdater] checkForUpdates:sender];
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

-(void)userDefaultsDidChange:(NSNotification*)aNotification{
    NSDictionary* prefDict = [self.defaults persistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];
    
    BOOL needRegister = NO;
    if (![prefDict[MASPrefKeyCopyShortcut] isEqualTo:self.prefsDict[MASPrefKeyCopyShortcut]]){
        self.prefsDict[MASPrefKeyCopyShortcut] = prefDict[MASPrefKeyCopyShortcut];
        needRegister = YES;
    }
    if(![prefDict[MASPrefKeyDefaultFormatShortcut] isEqualTo:self.prefsDict[MASPrefKeyDefaultFormatShortcut]]){
        self.prefsDict[MASPrefKeyDefaultFormatShortcut] = prefDict[MASPrefKeyDefaultFormatShortcut];
        needRegister = YES;
    }
    if(![prefDict[MASPrefKeyAlterFormatShortcut] isEqualTo:self.prefsDict[MASPrefKeyAlterFormatShortcut]]){
        self.prefsDict[MASPrefKeyAlterFormatShortcut] = prefDict[MASPrefKeyAlterFormatShortcut];
        needRegister = YES;
    }
    
    if (needRegister) {
        [self registerShortcuts];
        NSLog(@"==> re register shortcuts");
    }
    NSLog(@"==> userDefaultsDidChange");
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
    [statusMenu addItemWithTitle:@"Check for Updates..." action:@selector(checkForUpdates:) keyEquivalent:@""];
    [statusMenu addItem:[NSMenuItem separatorItem]];
    [statusMenu addItemWithTitle:@"Quit" action:@selector(quitApp) keyEquivalent:@"q"];
    self.statusItem.menu = statusMenu;
}

-(void)setupPreferences
{
    self.prefController = [[CMPreferencesController alloc] initWithWindowNibName:@"CMPreferencesController"];
    
    NSDictionary* prefsDict = [self.defaults persistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];
    self.prefsDict = [[NSMutableDictionary dictionaryWithDictionary:prefsDict] mutableCopy];
    
    if (![self.defaults objectForKey:CopyMateNotFirstRun]) {
        
        self.prefsDict[CopyMateDefaultFormat] = @"%@\n%@";
        self.currentFormat = self.prefsDict[CopyMateDefaultFormat];
        
        self.prefsDict[CopyMateAlterFormat] = @"%@ %@";
        self.currentFormat = self.prefsDict[CopyMateAlterFormat];
        
        self.prefsDict[CopyMateStartAtLogin] = @NO;
        
        self.prefsDict[CopyMateNotFirstRun] = @YES;
        
        [self persistDefaults];
    }
    
    for (id key in self.prefsDict){
        [self.prefsDict addObserver:self forKeyPath:[key description]
                            options:NSKeyValueObservingOptionNew context:(__bridge void *)(key)];
    }

    self.currentFormat = self.prefsDict[CopyMateDefaultFormat];
    self.prefController.prefsDict = self.prefsDict;
}

-(void)persistDefaults
{
    NSLog(@"==> persistDefaults");
    [self.defaults setPersistentDomain:self.prefsDict forName:[[NSBundle mainBundle] bundleIdentifier]];
}

-(void)registerShortcuts
{
    NSLog(@"==> start registerShortcuts");
    void(^copyHandler)(void) = ^{
        [self copyAppendImpl];
    };
    
    void(^defaultFormatHandler)(void) = ^{
        self.currentFormat = self.prefsDict[CopyMateDefaultFormat];
        [self postUserNotification:@"Default format is actived"];
        NSLog(@"==> switch to default format");
    };
    
    void(^alterFormatHandler)(void) = ^{
        self.currentFormat = self.prefsDict[CopyMateAlterFormat];
        [self postUserNotification:@"Alternative format is actived"];
        NSLog(@"==> switch to alter format");
    };
    
    [self registerShortcut:MASPrefKeyCopyShortcut Keycode:kVK_ANSI_C Handler:copyHandler];
    [self registerShortcut:MASPrefKeyDefaultFormatShortcut Keycode:kVK_ANSI_1 Handler:defaultFormatHandler];
    [self registerShortcut:MASPrefKeyAlterFormatShortcut Keycode:kVK_ANSI_2 Handler:alterFormatHandler];
    
    NSLog(@"==> end registerShortcuts");
}

-(void)copyAppendImpl
{
    @try
    {
        NSString* lastCopyString = [[NSPasteboard generalPasteboard] stringForType:NSStringPboardType];
        
        QCUIElement *focusedElement = [QCUIElement focusedElement];
        QCUIElement *sourceApplicationElement = [focusedElement application];
        NSString *editString = [sourceApplicationElement readString];
        
        if (editString) {
            NSString* appendString = [NSString stringWithFormat:self.currentFormat, lastCopyString, editString];
            NSLog(@"==> append string result:%@", appendString);
            
            [[NSPasteboard generalPasteboard] clearContents];
            [[NSPasteboard generalPasteboard] writeObjects:@[appendString]];
        }

    }
    @catch (NSException *exception)
    {
        NSLog(@"==> copyAppendImpl failed:%@", exception.reason);
    }
}

-(void)registerShortcut:(NSString*) defaultsKey
                Keycode:(NSUInteger) defaultKeyCode
                Handler:(void(^)(void)) handler
{
    if ([self.defaults objectForKey:defaultsKey]) {
        [MASShortcut registerGlobalShortcutWithUserDefaultsKey:defaultsKey handler:handler];
    } else{
        MASShortcut* shortcut = [MASShortcut shortcutWithKeyCode:defaultKeyCode modifierFlags:NSControlKeyMask|NSShiftKeyMask];
        self.prefsDict[defaultsKey] = [shortcut data];
        [self persistDefaults];
        [MASShortcut addGlobalHotkeyMonitorWithShortcut:shortcut handler:handler];
    }
}

-(void)postUserNotification:(NSString*)message
{
    [[NSUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];
    NSUserNotification* notification = [NSUserNotification new];
    notification.title = @"CopyMate";
    notification.informativeText = message;
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
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
