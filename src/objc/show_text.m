#import <Cocoa/Cocoa.h>
#import "show_text.h"

static NSWindow *overlayWindow = nil;
static NSTextField *textField = nil;
static NSMutableString *textBuffer = nil;
static NSTimer *clearTimer = nil;

void init_cocoa_app(void) {
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    [NSApp activateIgnoringOtherApps:YES];
}

void show_text_for_duration(const char *utf8_text, int seconds) {
    NSString *newText = [[NSString alloc] initWithUTF8String:utf8_text];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!overlayWindow) {
            NSScreen *mainScreen = [NSScreen mainScreen];
            NSRect screenFrame = mainScreen.frame;

            NSRect windowFrame = NSMakeRect(0, 0, screenFrame.size.width, 100);
            overlayWindow = [[NSWindow alloc] initWithContentRect:windowFrame
                                                         styleMask:NSWindowStyleMaskBorderless
                                                           backing:NSBackingStoreBuffered
                                                             defer:NO];
            [overlayWindow setOpaque:NO];
            [overlayWindow setBackgroundColor:[NSColor clearColor]];
            [overlayWindow setLevel:NSScreenSaverWindowLevel]; // 在最上层
            [overlayWindow setIgnoresMouseEvents:YES]; // 事件穿透
            [overlayWindow setAlphaValue:1.0];
            [overlayWindow setReleasedWhenClosed:NO];

            NSView *contentView = [[NSView alloc] initWithFrame:windowFrame];
            contentView.wantsLayer = YES;
            contentView.layer.backgroundColor = [[NSColor colorWithWhite:0 alpha:0.5] CGColor];

            textField = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 20, windowFrame.size.width - 40, 60)];
            textField.editable = NO;
            textField.bezeled = NO;
            textField.drawsBackground = NO;
            textField.textColor = [NSColor whiteColor];
            textField.font = [NSFont systemFontOfSize:20];
            textField.alignment = NSTextAlignmentCenter;
            textField.lineBreakMode = NSLineBreakByWordWrapping;
            textField.usesSingleLineMode = NO;

            [contentView addSubview:textField];
            [overlayWindow setContentView:contentView];

            NSRect pos = windowFrame;
            pos.origin.y = 0; // 屏幕底部
            [overlayWindow setFrame:pos display:YES];
            [overlayWindow orderFrontRegardless];
        }

        // 初始化缓存
        if (!textBuffer) {
            textBuffer = [NSMutableString new];
        }

        // if (textBuffer.length > 0) {
        //     [textBuffer appendString:@" "];
        // }
        [textBuffer appendString:newText];
        textField.stringValue = textBuffer;

        // 重置定时器
        if (clearTimer) {
            [clearTimer invalidate];
        }

        clearTimer = [NSTimer scheduledTimerWithTimeInterval:seconds
                                                      repeats:NO
                                                        block:^(NSTimer * _Nonnull timer) {
            [textBuffer setString:@""];
            textField.stringValue = @"";
            [overlayWindow orderOut:nil];
            overlayWindow = nil;
            textField = nil;
            clearTimer = nil;
        }];
    });
}

static NSString *KeyNameFromKeyCode(CGKeyCode keyCode) {
    // 手动 keycode -> 名称映射表
    switch (keyCode) {
        case 0: return @"a";
        case 1: return @"s";
        case 2: return @"d";
        case 3: return @"f";
        case 4: return @"h";
        case 5: return @"g";
        case 6: return @"z";
        case 7: return @"x";
        case 8: return @"c";
        case 9: return @"V";
        case 11: return @"b";
        case 12: return @"q";
        case 13: return @"w";
        case 14: return @"e";
        case 15: return @"r";
        case 16: return @"y";
        case 17: return @"t";
        case 18: return @"1";
        case 19: return @"2";
        case 20: return @"3";
        case 21: return @"4";
        case 22: return @"6";
        case 23: return @"5";
        case 24: return @"=";
        case 25: return @"9";
        case 26: return @"7";
        case 27: return @"-";
        case 28: return @"8";
        case 29: return @"0";
        case 30: return @"]";
        case 31: return @"o";
        case 32: return @"u";
        case 33: return @"[";
        case 34: return @"i";
        case 35: return @"p";
        case 36: return @"<Return>";
        case 37: return @"l";
        case 38: return @"j";
        case 39: return @"'";
        case 40: return @"k";
        case 41: return @";";
        case 42: return @"\\";
        case 43: return @","; 
        case 44: return @"/";
        case 45: return @"n";
        case 46: return @"m";
        case 47: return @".";
        case 48: return @"<Tab>";
        case 49: return @"<Space>";
        case 50: return @"`";
        case 51: return @"<Delete>";
        case 53: return @"<Escape>";
        case 123: return @"<Left>";
        case 124: return @"<Right>";
        case 125: return @"<Down>";
        case 126: return @"<Up>";
        case 122: return @"<F1>";
        case 120: return @"<F2>";
        case 99:  return @"<F3>";
        case 118: return @"<F4>";
        case 96:  return @"<F5>";
        case 97:  return @"<F6>";
        case 98:  return @"<F7>";
        case 100: return @"<F8>";
        case 101: return @"<F9>";
        case 109: return @"<F10>";
        case 103: return @"<F11>";
        case 111: return @"<F12>";
        default:
            return [NSString stringWithFormat:@"<%d>", keyCode];
    }
}

char *key_string_from_CGEvent(CGEventRef event) {
    @autoreleasepool {
        if (!event) return NULL;

        CGEventFlags flags = CGEventGetFlags(event);
        CGKeyCode keyCode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);

        NSMutableString *result = [NSMutableString string];

        if (flags & kCGEventFlagMaskCommand) {
            [result appendString:@"⌘"];
        }
        if (flags & kCGEventFlagMaskShift) {
            [result appendString:@"⇧"];
        }
        if (flags & kCGEventFlagMaskAlternate) {
            [result appendString:@"⌥"];
        }
        if (flags & kCGEventFlagMaskControl) {
            [result appendString:@"⌃"];
        }

        [result appendString:KeyNameFromKeyCode(keyCode)];

        const char *utf8 = [result UTF8String];
        if (!utf8) return NULL;

        char *cstr = malloc(strlen(utf8) + 1);
        if (cstr) {
            strcpy(cstr, utf8);
        }
        return cstr;
    }
}