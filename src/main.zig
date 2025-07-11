const std = @import("std");
// const listen_keyboard = @import("listen_keyboard");
const c = @cImport({
    @cDefine("CFSTR(str)", "0"); // 临时将 CFSTR 定义为 0，避免翻译错误
    @cInclude("ApplicationServices/ApplicationServices.h");
    @cInclude("objc/show_text.h");
});

/// 打开一个App
fn openApp(will_opened_app: [] const u8) !void {
    const allocator = std.heap.page_allocator;
    const last_foused_app = get_focused_app_name();
    // a -> b -> b
    // save a
    // b -> b -> a
    const path_name = a:{
        if(last_foused_app)|last_foused_app_just| {
            const last_foused_app_just_slice: [] const u8 = std.mem.span(last_foused_app_just);
            // 如果要打开的App就是当前App本身
            if(std.mem.eql(u8, last_foused_app_just_slice, will_opened_app)) {
                if(last_app)|last_app_just| {
                    // std.debug.print("inner:last_foused_app_just={s},will_opened_app={s},saved_last_app={?s}\n", .{last_foused_app_just_slice,will_opened_app,last_app});
                   break :a last_app_just; 
                }
            } else {
                const owner = try allocator.dupe(u8, last_foused_app_just_slice);
                if(last_app)|a| allocator.free(a);
                last_app = owner;
            }
            // std.debug.print("last_foused_app_just={s},will_opened_app={s},saved_last_app={?s}\n", .{last_foused_app_just_slice,will_opened_app,last_app});
        }
        break :a will_opened_app;
    };
    const cstr_path_name = try allocator.dupeZ(u8, path_name);
    defer allocator.free(cstr_path_name);
    const success = open_and_activateApp(cstr_path_name.ptr);
    _ = success;
    // std.debug.print("success={}", .{success});
    // std.debug.print("cstr_path_name={s}\n", .{cstr_path_name});
    // const path = c.CFStringCreateWithCString(c.kCFAllocatorDefault, cstr_path_name.ptr, c.kCFStringEncodingUTF8) orelse return error.FailedCreatePath;
    // defer c.CFRelease(path);
    // const url = c.CFURLCreateWithFileSystemPath(c.kCFAllocatorDefault, path, c.kCFURLPOSIXPathStyle, c.TRUE) orelse return error.FailedCreateURL;
    // defer c.CFRelease(url);
    // _ = c.LSOpenCFURLRef(url, null);


}

test openApp {
    // try openApp("/Applications/Visual Studio Code.app");
}
const Fn = fn() anyerror!void;
const Task = struct {
    [] const u8,
    [] const u8,
};
/// when ⌘⌃g open /Applications/Google Chrome.app.
/// Press ⌘⌃g to open  /Applications/Google Chrome.app
/// 
var keyboard_tasks : [] Task = &.{};



var show_log = false;
var show_key_text = false;
var last_app: ?[] const u8 = null;
// 全局事件回调
fn eventTapCallback(proxy: c.CGEventTapProxy, type_: c.CGEventType, event: c.CGEventRef, userInfo: ?*anyopaque) callconv(.C) c.CGEventRef {
    _ = proxy;
    _ = userInfo;
    // const allocator = std.heap.page_allocator;
    if (type_ == c.kCGEventKeyDown) {
        const key_str = c.key_string_from_CGEvent(event);
        defer std.c.free(key_str);
        if(show_key_text) c.show_text_for_duration(key_str, 1);
        const key_name: [] const u8 = std.mem.span(key_str);
        if(show_log) {
            std.debug.print("Press {s} \n", .{key_name});
        }

        if(std.mem.eql(u8, "⌘⌥⌃k", std.mem.span(key_str))) {
            if(show_key_text) {
                c.show_text_for_duration("关闭屏幕显示 ", 1);
                show_key_text = false;
            } else {
                c.show_text_for_duration("开启屏幕显示 ", 1);
                show_key_text = true;
            }
        }
        for(keyboard_tasks) |task| {
            const press,const app = task;
            if(std.mem.eql(u8, press, std.mem.span(key_str))) {
                openApp(app) catch {
                    std.debug.print("Failed to open app {s}", .{app});
                };
                return null;
            }
        }
    }
    return event;
}  

fn parseConfig() !void {
    const allocator = std.heap.page_allocator;
    const home = try std.process.getEnvVarOwned(allocator, "HOME");
    defer allocator.free(home);

    var dir = try std.fs.openDirAbsolute(home, .{});
    defer dir.close();
    const config_path =".config/listen_keyboard/config";
    try dir.makePath(std.fs.path.dirname(config_path) orelse unreachable);
    var file  = dir.createFile(config_path, .{.read = true,.truncate = false}) catch |e| switch (e) {
        else => {
            std.debug.print("error = {}", .{e});
            std.process.exit(1);
        }
    };
    defer file.close();
    const content = file.readToEndAlloc(allocator, 1024 * 1024 * 100) catch |e| {
            std.debug.print("file.readToEndAlloc error = {}", .{e});
            std.process.exit(1);
        unreachable;
    };
    defer allocator.free(content);

    var iterator = std.mem.splitScalar(u8, content, '\n');
    var list = std.ArrayList(Task).init(allocator);
    defer list.deinit();
    while(iterator.next()) | line | {
        if(line.len < 7) continue;
        if(line[0] == '#') continue;
        if(std.mem.startsWith(u8, line, "Press")) {
            if(std.mem.indexOf(u8, line, "open"))|open_start| {
                const key_str = line[5..open_start];
                const app_path = line[open_start+4..];
                try list.append(.{
                    try allocator.dupe(u8, std.mem.trim(u8,key_str, " ")),
                    try allocator.dupe(u8, std.mem.trim(u8,app_path, " ")),
                });
            } else {
                std.debug.print("Parse error = {s}\n", .{line});
                std.process.exit(0);
            }
        }
    }
    keyboard_tasks = (try list.clone()).items;
    if(show_log) {
        for(keyboard_tasks)|t| {
            std.debug.print("key={s},app={s}\n", .{t[0],t[1]});
        }
    }
}
test "parse config" {
    try parseConfig();
}
pub fn main() !void {
    // std.process.exit(0);
    {
        var args = std.process.args(); 
        defer args.deinit();
        while (args.next()) |arg| {
            if(std.mem.eql(u8, arg, "--verbose")) {
                show_log = true;
            } else if(std.mem.eql(u8, arg, "--key_text")) {
                show_key_text = true;
            } else if(std.mem.eql(u8, arg, "--help")) {
                std.debug.print(\\ 监听系统级别全局按键，用于显示在屏幕上，打开App
                \\ 配置文件 $HOME/.config/listen_keyboard/config
                \\ listen_keyboard [Options]
                \\ --verbose  显示日志
                \\ --key_text 将按键显示在屏幕最上方
                \\ --help     显示帮助
                \\
                , .{});
                std.process.exit(0);
            }

        }
    }
    try parseConfig();
    c.init_cocoa_app();
    std.debug.print("开启/关闭屏幕显示快捷键 ⌘⌥⌃k\n", .{});
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

test "mytest" {
    const pid = try std.posix.fork();
    const pid2 = try std.posix.fork();
    std.debug.print("pid={?},pid2={?}\n", .{pid,pid2});
}

fn createCFString(c_str: [*:0]const u8) c.CFStringRef {
    const cf_str = c.CFStringCreateWithCString(
        c.kCFAllocatorDefault,
        c_str,
        c.kCFStringEncodingUTF8
    );
    if (cf_str == null) @panic("Failed to create CFString");
    return cf_str;
}
test "span" {
    const b:[*c] const u8  = "helo";
    const a : [] const u8 = std.mem.span(b);
    std.debug.print("{s}", .{a});
}

extern fn get_focused_app_name() callconv(.C) ?[*:0] const u8;
extern fn open_and_activateApp([*:0] const u8) callconv(.C) u8;

test "show_floating_text" {
}
test "get current app" {
    const name = get_focused_app_name();
    std.debug.print("{?s}", .{name});
}