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
#import "NSString+Extensions.h"
#import <Sparkle/Sparkle.h>


typedef enum {
    PREF_GENERAL_TAG    = 0,
    PREF_SHORTCUTS_TAG  = 1,
    PREF_ABOUT_TAG      = 2,
}EnumPrefTags;

@interface CMPreferencesController ()<NSTextFieldDelegate>

@property (weak, nonatomic) IBOutlet NSToolbar* toolbar;
@property (weak, nonatomic) IBOutlet MASShortcutView* appendCopyshortcutView;
@property (weak, nonatomic) IBOutlet MASShortcutView* defaultFormatShortcutView;
@property (weak, nonatomic) IBOutlet MASShortcutView* alterFormatShortcutView;

@property (weak, nonatomic) IBOutlet NSView* generalView;
@property (weak, nonatomic) IBOutlet NSView* shortcutsView;
@property (weak, nonatomic) IBOutlet NSView* aboutView;

@property (weak, nonatomic) IBOutlet NSButton* startupCheckbox;
@property (weak, nonatomic) IBOutlet NSButton* autoUpdateCheckbox;
@property (weak, nonatomic) IBOutlet NSTextField* defaultTextField;
@property (weak, nonatomic) IBOutlet NSTextField* alterTextField;
@property (weak, nonatomic) IBOutlet NSButton* homepageButton;
@property (weak, nonatomic) IBOutlet NSTextField* versionLabel;
@property (weak, nonatomic) IBOutlet NSTextField* lastUpdateLabel;

@property (assign, nonatomic) NSSize generalSize;
@property (assign, nonatomic) NSSize shortcutSize;
@property (assign, nonatomic) NSSize aboutSize;

@end

@implementation CMPreferencesController

#pragma mark NSWindow

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
    [self setupUI];
}

#pragma mark NSTextFieldDelegate

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    if ([fieldEditor.string countOccurencesOfString:@"%@"] == 2) {
        return YES;
    } else{
        NSAlert* alert = [NSAlert alertWithMessageText:@"Invalid format" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"format string should only contain two %@", @"%@"];
        [alert runModal];
        return NO;
    }
}

#pragma mark UI

-(void)setupUI
{
    self.generalSize = self.generalView.frame.size;
    self.shortcutSize = self.shortcutsView.frame.size;
    self.aboutSize = self.aboutView.frame.size;
    
    self.appendCopyshortcutView.associatedUserDefaultsKey = MASPrefKeyCopyShortcut;
    self.alterFormatShortcutView.associatedUserDefaultsKey = MASPrefKeyAlterFormatShortcut;
    self.defaultFormatShortcutView.associatedUserDefaultsKey = MASPrefKeyDefaultFormatShortcut;
    
    NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
    [self.versionLabel setStringValue:infoDict[@"CFBundleShortVersionString"]];
    
    NSDateFormatter* dateFormatter = [NSDateFormatter new];
    dateFormatter.locale = [NSLocale currentLocale];
    dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    dateFormatter.timeStyle = NSDateFormatterMediumStyle;
    NSDate* date = [[SUUpdater sharedUpdater] lastUpdateCheckDate];
    NSString* dateString = [NSString stringWithFormat:@"Last check time: %@",[dateFormatter stringFromDate:date]];
    [self.lastUpdateLabel setStringValue:dateString];
    
    NSMutableAttributedString* title = [[NSMutableAttributedString alloc] initWithString:CopyMateHome];
    NSRange titleRange = NSMakeRange(0, [CopyMateHome length]);
    [title addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSSingleUnderlineStyle] range:titleRange];
    [title addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:titleRange];
    [self.homepageButton setAttributedTitle:title];
    
    NSString* format = self.prefsDict[CopyMateDefaultFormat];
    if (format) {
        [self.defaultTextField setStringValue:[format stringByEscapeControlCharacters]];
    }
    
    format = self.prefsDict[CopyMateAlterFormat];
    if (format) {
        [self.alterTextField setStringValue:[format stringByEscapeControlCharacters]];
    }
    
    self.defaultTextField.delegate = self;
    self.alterTextField.delegate = self;
    
    self.window.contentView = self.generalView;
}

-(void)displayWindow
{
    [self.window makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
}

-(IBAction)showPrefView:(id)sender
{
    NSToolbarItem* tab = (NSToolbarItem*)sender;
    NSView* view = [self viewForTag:tab.tag];
    
    [self resizeWindowWithContentSize:[self viewSizeForTag:tab.tag] animated:YES];
    self.window.contentView = view;
    [self.window setViewsNeedDisplay:YES];
}

- (void)resizeWindowWithContentSize:(NSSize)contentSize animated:(BOOL)animated {
    CGFloat titleBarHeight = self.window.frame.size.height - ((NSView*)self.window.contentView).frame.size.height;
    CGSize windowSize = CGSizeMake(contentSize.width, contentSize.height + titleBarHeight);

    NSRect windowFrame = CGRectMake(self.window.frame.origin.x, self.window.frame.origin.y, windowSize.width, windowSize.height);
    
    [self.window setFrame:windowFrame display:YES animate:animated];
    [self.window displayIfNeeded];
}

-(NSView*)viewForTag:(NSUInteger)tag{
    __weak NSView* view = nil;
    switch (tag) {
        case PREF_SHORTCUTS_TAG:
        {
            view = self.shortcutsView;
            break;
        }
        case PREF_ABOUT_TAG:
        {
            view = self.aboutView;
            break;
        }
        case PREF_GENERAL_TAG:
        default:
        {
            view = self.generalView;
            break;
        }
    }
    return view;
}

-(NSSize)viewSizeForTag:(NSUInteger)tag{
    switch (tag) {
        case PREF_SHORTCUTS_TAG:
        {
            return self.shortcutSize;
        }
        case PREF_ABOUT_TAG:
        {
            return self.aboutSize;
        }
        case PREF_GENERAL_TAG:
        default:
        {
            return self.generalSize;
        }
    }
}

#pragma mark IBActions
- (IBAction)toggleLaunchOnLogin:(id)sender
{
    NSButton* button = (NSButton*)sender;
    BOOL enable = button.state == 0? NO:YES;
    self.prefsDict[CopyMateStartAtLogin] = @(enable);
}

- (IBAction)openHomepage:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:CopyMateHomeLink]];
}

- (IBAction)enterKeyPressed:(id)sender{
    NSTextField* textField = (NSTextField*)sender;
    if (textField == self.defaultTextField) {
        self.prefsDict[CopyMateDefaultFormat] = [textField.stringValue stringByEscapeControlCharacters];
    } else if (textField == self.alterTextField){
        self.prefsDict[CopyMateAlterFormat] = [textField.stringValue stringByEscapeControlCharacters];
    }
}

@end
