const std = @import("std");
// const listen_keyboard = @import("listen_keyboard");
const c = @cImport({
    @cInclude("ApplicationServices/ApplicationServices.h");
});

/// 打开一个App
fn openApp(name: [] const u8) !void {
    const path = c.CFStringCreateWithCString(c.kCFAllocatorDefault, name.ptr, c.kCFStringEncodingUTF8) orelse return error.FailedCreatePath;
    defer c.CFRelease(path);
    const url = c.CFURLCreateWithFileSystemPath(c.kCFAllocatorDefault, path, c.kCFURLPOSIXPathStyle, c.TRUE) orelse return error.FailedCreateURL;
    defer c.CFRelease(url);
    _ = c.LSOpenCFURLRef(url, null);

}

test openApp {
    // try openApp("/Applications/Visual Studio Code.app");
}
const Fn = fn() anyerror!void;
const Task = struct {
    struct {Keys,u64},
    Fn,
};
fn hello() !void {
    std.debug.print("hello",.{});
}
fn openGoogle() !void {
    try openApp("/Applications/Google Chrome.app");
}
const Keys = enum(i64) {
    Kw = 13,
    Kc = 8,
    Kg = 5,
    Kt = 17,
    Kq = 12,
    Kv = 9,
    Ka = 0
};
const keyboard_tasks = [_]Task{
    .{
         // Control + Commnad + g
        .{Keys.Kg,c.kCGEventFlagMaskControl | c.kCGEventFlagMaskCommand},
        struct {
            pub fn call()!void{
                try openApp("/Applications/Google Chrome.app");
            }
        }.call,
    },
    .{
        // Contrl + Command + t
        .{Keys.Kt,c.kCGEventFlagMaskControl | c.kCGEventFlagMaskCommand},
        struct {
            pub fn call()!void{
                try openApp("/System/Applications/Utilities/Terminal.app");
            }
        }.call,
    },
    .{
        // Contrl + Command + c
        .{Keys.Kc,c.kCGEventFlagMaskControl | c.kCGEventFlagMaskCommand},
        struct {
            pub fn call()!void{
                try openApp("/Applications/Visual Studio Code.app");
            }
        }.call,
    },
    .{
        .{Keys.Ka,c.kCGEventFlagMaskControl | c.kCGEventFlagMaskCommand},
        struct {
            pub fn call()!void{
                try openApp("/Applications/QQ.app");
            }
        }.call,
    },
    .{
        .{Keys.Kw,c.kCGEventFlagMaskControl | c.kCGEventFlagMaskCommand},
        struct {
            pub fn call()!void{
                try openApp("/Applications/WeChat.app");
            }
        }.call,
    }
};

// 全局事件回调
fn eventTapCallback(proxy: c.CGEventTapProxy, type_: c.CGEventType, event: c.CGEventRef, userInfo: ?*anyopaque) callconv(.C) c.CGEventRef {
    _ = proxy;
    _ = userInfo;

    if (type_ == c.kCGEventKeyDown) {
        const flags = c.CGEventGetFlags(event);
        // 如果修饰键没有按下，则忽略
        if(flags == 0x100) return event;
        const keyCode = c.CGEventGetIntegerValueField(event, c.kCGKeyboardEventKeycode);
        // 从配置列表中匹配对应的函数
        inline for(keyboard_tasks)|task| {
            // 这个条件判断，会判断两个修饰键同时按下.
            if(keyCode == @intFromEnum(task[0][0]) and  flags &  task[0][1] == task[0][1]) {
                _ = std.Thread.spawn(.{}, task[1],.{}) catch {
                    // 单独起一个系统线程执行，防止block时间太久，被系统限制。
                    std.debug.print("spawn error", .{});
                };
                // 屏蔽快捷键,防止其他程序处理。
                return null;
            }
        }
        std.debug.print("KeyCode: {}, Flags: 0x{x}\n", .{ keyCode, flags });
    }

    return event;
}
pub fn main() !void {
     
    // 创建 CGEventTap
    // 我也不知道为什么要 1 << ,反正能正常运行
    const eventMask = (1 << c.kCGEventKeyDown);
    const tap = c.CGEventTapCreate(
        c.kCGSessionEventTap,
        c.kCGHeadInsertEventTap,
        0,
        eventMask,
        eventTapCallback,
        null,
    ) orelse {
        // 没有赋予Accessibility权限会走这里
        std.debug.print("Failed to create event tap. Check Accessibility permissions.\n", .{});
        std.process.exit(0);
    };
    defer c.CFRelease(tap);

    // 将事件 tap 添加到运行循环
    const runLoopSource = c.CFMachPortCreateRunLoopSource(c.kCFAllocatorDefault, tap, 0) orelse {
        std.debug.print("Failed to create run loop source.\n", .{});
        return error.RunLoopSourceCreationFailed;
    };
    defer c.CFRelease(runLoopSource);

    c.CFRunLoopAddSource(c.CFRunLoopGetCurrent(), runLoopSource, c.kCFRunLoopCommonModes);
    c.CGEventTapEnable(tap, true);
    // 运行循环
    std.debug.print("Running CFRunLoop...\n", .{});
    // 会阻塞
    c.CFRunLoopRun();
    // 下面这种方式可以只运行一次，自己写循环。
    // while(true){
    //     _ = c.CFRunLoopRunInMode(c.kCFRunLoopDefaultMode, 1, 0);
    //     // std.debug.print("run loop run in mode\n", .{});
    //     std.time.sleep(std.time.ns_per_ms * 100);
    // }
}

