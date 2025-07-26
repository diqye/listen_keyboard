#import <Cocoa/Cocoa.h>
#import "show_text.h"
// AXError.h
// /Library/Developer/CommandLineTools/SDKs/MacOSX14.5.sdk/System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/HIServices.framework/Versions/A/Headers/AXError.h
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
            // contentView.layer.backgroundColor = [[NSColor colorWithWhite:0 alpha:0.3] CGColor];
            contentView.layer.backgroundColor = [[NSColor colorWithWhite:0 alpha:0] CGColor];

            textField = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 20, windowFrame.size.width - 40, 60)];
            textField.editable = NO;
            textField.bezeled = NO;
            textField.drawsBackground = NO;
            textField.textColor = [NSColor magentaColor];
            textField.font = [NSFont systemFontOfSize:20];
            textField.alignment = NSTextAlignmentCenter;
            textField.lineBreakMode = NSLineBreakByWordWrapping;
            textField.usesSingleLineMode = NO;

            // Create shadow
            NSShadow *textShadow = [[NSShadow alloc] init];
            [textShadow setShadowColor:[[NSColor blackColor] colorWithAlphaComponent:0.5]];
            [textShadow setShadowOffset:NSMakeSize(2.0, -2.0)];
            [textShadow setShadowBlurRadius:3.0];

            // Apply shadow to text
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:textField.stringValue];
            NSRange range = NSMakeRange(0, [attributedString length]);
            [attributedString addAttribute:NSShadowAttributeName value:textShadow range:range];
            [attributedString addAttribute:NSForegroundColorAttributeName value:[NSColor magentaColor] range:range];
            [attributedString addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:20] range:range];
            textField.attributedStringValue = attributedString;

            [contentView addSubview:textField];
            [overlayWindow setContentView:contentView];

            NSRect pos = windowFrame;
            // pos.origin.y = 0; // 屏幕底层

            pos.origin.y = screenFrame.size.height - windowFrame.size.height - 50; // 屏幕上方
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
            // [textBuffer setString:@""];
            // textField.stringValue = @"";
            [overlayWindow orderOut:nil];
            textBuffer = nil;
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
        case 9: return @"v";
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
        case 36: return @"<enter>";
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
        case 48: return @"<tab>";
        case 49: return @"<space>";
        case 50: return @"`";
        case 51: return @"<backspace>";
        case 53: return @"<esc>";
        case 123: return @"<left>";
        case 124: return @"<right>";
        case 125: return @"<down>";
        case 126: return @"<up>";
        case 122: return @"<f1>";
        case 120: return @"<f2>";
        case 99:  return @"<f3>";
        case 118: return @"<f4>";
        case 96:  return @"<f5>";
        case 97:  return @"<f6>";
        case 98:  return @"<f7>";
        case 100: return @"<f8>";
        case 101: return @"<f9>";
        case 109: return @"<f10>";
        case 103: return @"<f11>";
        case 111: return @"<f12>";
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

void simulate_keyboard_input(const char *utf8_str) {
    @autoreleasepool {
        if (utf8_str == NULL) return;

        NSString *string = [NSString stringWithUTF8String:utf8_str];
        NSUInteger length = [string length];
        if (length == 0) return;

        UniChar *buffer = malloc(length * sizeof(UniChar));
        [string getCharacters:buffer range:NSMakeRange(0, length)];

        CGEventRef keyDown = CGEventCreateKeyboardEvent(NULL, 0, true);
        CGEventKeyboardSetUnicodeString(keyDown, length, buffer);
        CGEventPost(kCGSessionEventTap, keyDown);

        CGEventSetType(keyDown, kCGEventKeyUp);
        CGEventPost(kCGSessionEventTap, keyDown);

        CFRelease(keyDown);
        free(buffer);
    }
}
// 定义出参结构体
typedef struct {
    NSRunningApplication *ref; // 前台应用的引用
    pid_t pid;                 // 进程 ID int类型
    char *name;                // 应用名称（C 字符串）
} FrontmostAppInfo;

// 获取当前正在运行的App
uint frontmostApplication(FrontmostAppInfo *out_info) {
    // 检查辅助功能权限
    NSDictionary *options = @{(__bridge id)kAXTrustedCheckOptionPrompt: @YES};
    BOOL accessibilityEnabled = AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);
    if (!accessibilityEnabled) {
        NSLog(@"请在“系统设置 > 隐私与安全性 > 辅助功能”中授予辅助功能权限");
        return 1;
    }

    // 获取前台应用的进程 ID
    NSRunningApplication *frontmostApp = [[NSWorkspace sharedWorkspace] frontmostApplication];
    if (!frontmostApp) {
        NSLog(@"无法获取前台应用");
        return 2;
    }
    out_info->ref = frontmostApp;
    out_info->pid = frontmostApp.processIdentifier;
    // 将应用名称转换为 C 字符串
    NSString *appName = frontmostApp.localizedName;
    if (appName) {
        // 使用 strdup 分配内存，调用者需要释放
        out_info->name = strdup([appName UTF8String]);
        if (!out_info->name) {
            NSLog(@"无法分配应用名称内存");
            return 4;
        }
    } else {
        out_info->name = strdup(""); // 空名称
    }
    return 0;
}
// 从App中获取菜单栏
uint getMenubarRefFromPid(pid_t pid, AXUIElementRef* out_menubar) {
     // 创建前台应用的 Accessibility 元素
    AXUIElementRef appRef = AXUIElementCreateApplication(pid);
    if (!appRef) {
        NSLog(@"无法创建前台应用的 Accessibility 元素");
        return 3;
    }

    // 获取菜单栏
    AXUIElementRef menuBar = NULL;
    AXError error = AXUIElementCopyAttributeValue(appRef, kAXMenuBarAttribute, (CFTypeRef *)&menuBar);
    if (error != kAXErrorSuccess || !menuBar) {
        NSLog(@"无法获取前台应用的菜单栏，错误代码: %d", error);
        CFRelease(appRef);
        return 4;
    }
    CFRelease(appRef);
    *out_menubar = menuBar;
    return 0;
}

uint getChildren(AXUIElementRef ref,CFArrayRef* out_array,int* len){
    // 获取菜单栏中的所有子项（一级菜单）
    AXError error = AXUIElementCopyAttributeValue(ref, kAXChildrenAttribute, (CFTypeRef *)out_array);
    if (error != kAXErrorSuccess) {
        NSLog(@"无法获取菜单栏子项，错误代码: %d", error);
        return 5;
    }
    *len = CFArrayGetCount(*out_array);
    return 0;
}

typedef struct {
    AXUIElementRef element;
    char* name;
} Myvalue;
uint getValueAtIndex(CFArrayRef ref,int i,Myvalue* out){
    AXUIElementRef menuItem = (AXUIElementRef)CFArrayGetValueAtIndex(ref, i);
    CFStringRef title = NULL;
    AXError error = AXUIElementCopyAttributeValue(menuItem, kAXTitleAttribute, (CFTypeRef *)&title);
    if(error == kAXErrorNoValue) {
        // NSLog(@"没有title属性");
        out->element = menuItem;
        out->name = strdup([@"_no_title_" UTF8String]);
        return 0;
    }
    if (error != kAXErrorSuccess) {
        NSLog(@"无法获取菜单标题，错误代码: %d", error);
        return 1;
    }
    NSString *titleStr = (__bridge NSString *)title;
    out->element = menuItem;
    out->name = strdup([titleStr UTF8String]);
    return 0;
}

uint clickUIElement(AXUIElementRef ref) {
    AXError err = AXUIElementPerformAction(ref, kAXPressAction);
    if(err != kAXErrorSuccess) {
        NSLog(@"点击按钮失败，AXError: %d", err);
        return 1;
    }
    return 0;
}