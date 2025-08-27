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
    union(enum) {
        app: [] const u8,
        menu: [] const u8
    },
};
/// when ⌘⌃g open /Applications/Google Chrome.app.
/// Press ⌘⌃g to open  /Applications/Google Chrome.app
/// 
var keyboard_tasks : [] Task = &.{};



var show_log = false;
var show_key_text = false;
var last_app: ?[] const u8 = null;
/// 全局事件回调
fn eventTapCallback(proxy: c.CGEventTapProxy, type_: c.CGEventType, event: c.CGEventRef, userInfo: ?*anyopaque) callconv(.c) c.CGEventRef {
    _ = proxy;
    _ = userInfo;
    // const allocator = std.heap.page_allocator;
    if (type_ == c.kCGEventKeyDown) {
        const key_str = c.key_string_from_CGEvent(event);
        const key_str_zig:[] const u8 = std.mem.span(key_str);
        defer std.c.free(key_str);
        if(show_key_text) {
            if(
                std.mem.startsWith(u8, key_str_zig,"⌘") or
                std.mem.startsWith(u8, key_str_zig,"⇧") or
                std.mem.startsWith(u8, key_str_zig,"⌥") or
                std.mem.startsWith(u8, key_str_zig,"⌃") 
            ) {
                const allocator = std.heap.page_allocator;
                const new_str: [:0] u8 = std.fmt.allocPrintSentinel(allocator, " {s} ", .{key_str_zig},0) catch unreachable;
                defer allocator.free(new_str);
                c.show_text_for_duration(new_str, 1);
            } else {
                c.show_text_for_duration(key_str, 1);
            }
        }
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
            return null;
        }
        for(keyboard_tasks) |task| {
            const press,const action = task;
            if(std.mem.eql(u8, press, std.mem.span(key_str))) {
                switch (action) {
                    .app => |app| {
                        openApp(app) catch {
                            std.debug.print("Failed to open app {s}\n", .{app});
                        };
                    },
                    .menu => |menu| {
                        clickMenu(menu) catch {
                            std.debug.print("Failed to click menus {s}\n", .{menu});
                        };
                        // _ = std.Thread.spawn(.{}, clickMenu, .{menu}) catch {
                        //     std.debug.print("Failed to click menu {s}", .{menu});
                        // };

                    }
                }
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
    var list : std.ArrayList(Task) = .empty;
    defer list.deinit(allocator);
    while(iterator.next()) | line | {
        if(line.len < 7) continue;
        if(line[0] == '#') continue;
        if(std.mem.startsWith(u8, line, "Press")) {
            if(std.mem.indexOf(u8, line, "to open"))|open_start| {
                const key_str = line[5..open_start];
                const app_path = line[open_start+7..];
                try list.append(allocator,.{
                    try allocator.dupe(u8, std.mem.trim(u8,key_str, " ")),
                    .{
                        .app = try allocator.dupe(u8, std.mem.trim(u8,app_path, " ")),
                    },
                });
            } else if(std.mem.indexOf(u8, line, "to click"))|the_idx| {
                const key_str = line[5..the_idx];
                const app_path = line[the_idx+8..];
                try list.append(allocator,.{
                    try allocator.dupe(u8, std.mem.trim(u8,key_str, " ")),
                    .{
                        .menu = try allocator.dupe(u8, std.mem.trim(u8,app_path, " ")),
                    },
                });
            } else {
                std.debug.print("Parse error = {s}\n", .{line});
                std.process.exit(0);
            }
        }
    }
    keyboard_tasks = (try list.clone(allocator)).items;
    if(show_log) {
        for(keyboard_tasks)|t| {
            switch (t[1]) {
                .app => |app| {
                    std.debug.print("key={s},app={s}\n", .{t[0],app});
                },
                .menu => |menu|{
                    std.debug.print("key={s},menu={s}\n", .{t[0],menu});
                }
            }
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

extern fn get_focused_app_name()  ?[*:0] const u8;
extern fn open_and_activateApp([*:0] const u8)  u8;

test "show_floating_text" {
}
test "get current app" {
    const name = get_focused_app_name();
    std.debug.print("{?s}", .{name});
}

extern fn simulate_keyboard_input([*:0] const u8) void;
const Key = struct {
    key_code: u16,

    const Mask = struct {
        command: bool = false,
        shift: bool = false,
        control: bool = false,
        alternate: bool = false
    };
    fn sleep10ms() void {
        std.time.sleep(std.time.ns_per_ms * 10);
    }
    fn sleep(second: u32) void {
        std.time.sleep(std.time.ns_per_s * @as(u64,second));
    }
    fn sleep1s() void {
        std.time.sleep(std.time.ns_per_s * 1);
    }
    fn type_string(str: [] const u8) !void {
        const c_str = try std.heap.page_allocator.dupeZ(u8, str);
        defer std.heap.page_allocator.free(c_str);
        simulate_keyboard_input(c_str);
        // const source_ref = c.CGEventSourceCreate(c.kCGEventSourceStateHIDSystemState);
        // if(source_ref == null) {
        //     return error.ErrorSourceCreate;
        // }
        // defer c.CFRelease(source_ref);
        // for(str)|s| {
        //     std.time.sleep(std.time.ns_per_ms * 10);
        //     const key_event = c.CGEventCreateKeyboardEvent(source_ref, 0, true);
        //     if(key_event == null) return error.ErrorKeyboardEventCreate;
        //     defer c.CFRelease(key_event);
        //     var char: c.UniChar = @intCast(s);
        //     c.CGEventKeyboardSetUnicodeString(key_event, 1, &char);
        //     c.CGEventPost(c.kCGHIDEventTap, key_event);
        //     std.debug.print("{c}\n", .{s});
        // }

    }
    const Self = @This();
    fn mask2flag(mask:Mask) u64{
        var flag : c_int = 0;
        if(mask.command) {
            flag |= c.kCGEventFlagMaskCommand;
        }
        if(mask.shift) {
            flag |= c.kCGEventFlagMaskShift;
        }
        if(mask.control) {
            flag |= c.kCGEventFlagMaskControl;
        }
        if(mask.alternate) {
            flag |= c.kCGEventFlagMaskAlternate;
        }
        return @intCast(flag);
    }
    pub fn down(self: Self,mask:?Mask) !void {
        const source_ref = c.CGEventSourceCreate(c.kCGEventSourceStateHIDSystemState);
        if(source_ref == null) {
            return error.ErrorSourceCreate;
        }
        defer c.CFRelease(source_ref);
        const key_down_event = c.CGEventCreateKeyboardEvent(source_ref, self.key_code, true);
        if(key_down_event == null) return error.ErrorKeyboardEventCreate;
        defer c.CFRelease(key_down_event);
        if(mask)|m| {
            const flag = mask2flag(m);
            c.CGEventSetFlags(key_down_event, flag);
        }
        c.CGEventPost(c.kCGHIDEventTap, key_down_event);
    }
    pub fn up(self: Self,mask: ?Mask) !void {
        const source_ref = c.CGEventSourceCreate(c.kCGEventSourceStateHIDSystemState);
        if(source_ref == null) {
            return error.ErrorSourceCreate;
        }
        defer c.CFRelease(source_ref);
        const key_up_event = c.CGEventCreateKeyboardEvent(source_ref, self.key_code, false);
        if(key_up_event == null) return error.ErrorKeyboardEventCreate;
        defer c.CFRelease(key_up_event);
        if(mask)|m| {
            const flag = mask2flag(m);
            c.CGEventSetFlags(key_up_event, flag);
        }
        c.CGEventPost(c.kCGHIDEventTap, key_up_event);
    }
};

const Mouse = struct {
    point: c.CGPoint,
    source: c.CGEventSourceRef,

    const Self = @This();
    pub fn get_current_location() !struct {f32,f32} {
        const source = c.CGEventSourceCreate(c.kCGEventSourceStateHIDSystemState);
        if (source == null)  return error.EventSourceCreationFailed; 
        defer c.CFRelease(source);
        const event = c.CGEventCreate(source);
        if (event == null) return error.EventCreationFailed;
        defer c.CFRelease(event);
        const location = c.CGEventGetLocation(event);
        return .{@floatCast(location.x),@floatCast(location.y)};
    }
    pub fn init(x:f64,y:f64) !Self {
        const source = c.CGEventSourceCreate(c.kCGEventSourceStateHIDSystemState);
        if (source == null)  return error.EventSourceCreationFailed; 
        return .{
            .source = source,
            .point = c.CGPointMake(x,y),
        };
    }
    pub fn deinit(self: *Self) void {
        defer c.CFRelease(self.source);
    }
    pub fn move(self:*Self,x:?f64,y:?f64) !void {
        if(x) |val_x| if(y) |val_y| {
            self.point = c.CGPointMake(val_x, val_y);
        };
        // 移动鼠标到指定坐标 (x, y)
        // const move_event = c.CGEventCreateMouseEvent(
        //     self.source,
        //     c.kCGEventMouseMoved,
        //     self.point,
        //     c.kCGMouseButtonLeft // 忽略此参数，仅用于移动
        // );
        // if (move_event == null) return error.MouseEventCreationFailed;
        // defer c.CFRelease(move_event);
        // c.CGEventPost(c.kCGHIDEventTap, move_event);
        try self.post_event(c.kCGEventMouseMoved,c.kCGMouseButtonLeft);
    }
    pub fn post_event(self: Self,mouse_type: c_uint, button:u32) !void {
        const mouse_event = c.CGEventCreateMouseEvent(
            self.source, 
            mouse_type, 
            self.point,
            button);
        if(mouse_event == null) return error.MouseEventCreationFailed;
        defer c.CFRelease(mouse_event);
        c.CGEventPost(c.kCGHIDEventTap, mouse_event);
    }
    pub fn left_down(self: Self) !void {
        try self.post_event(c.kCGEventLeftMouseDown, c.kCGMouseButtonLeft);
    }
    pub fn left_up(self: Self) !void {
        try self.post_event(c.kCGEventLeftMouseUp, c.kCGMouseButtonLeft);
    }
    pub fn right_down(self: Self) !void {
        try self.post_event(c.kCGEventRightMouseDown, c.kCGMouseButtonRight);
    }
    pub fn right_up(self: Self) !void {
        try self.post_event(c.kCGEventRightMouseUp, c.kCGMouseButtonRight);
    }

};

const log = std.log.scoped(.mytest);
test Mouse {
    const x,const y = try Mouse.get_current_location();
    std.debug.print("x={d:.2},y={d:.2}\n", .{x,y});

    // var mouse = try Mouse.init(100, 100);
    // try mouse.move(null,null);
    // Key.sleep1s();
    // std.debug.print("Done\n", .{});
}
test Key {
    const str = "测试测试😊";
    const view = try std.unicode.Utf8View.init(str);
    var iterator = view.iterator();
    while(iterator.nextCodepointSlice()) |slice| {
        std.debug.print("len={},str={s}\n", .{slice.len,slice});
    }
    std.process.exit(0);
    std.debug.print("测试key是否有效", .{});
    try Key.type_string("😊");
    Key.sleep10ms();
    std.unicode.fmtUtf8("你好呀").data;
}
test "mydiqye-" {
    try clickMenu("Window  -> Move & Resize");
}
fn clickMenu(menu_path: [] const u8) !void {
    const allocator = std.heap.page_allocator;
    var menu_list = try menuPath2list(allocator, menu_path);
    defer menu_list.deinit(allocator);

    var app_info = r: {
        var app_info:AppInfo = undefined;
        const error_code = frontmostApplication(&app_info);
        if(error_code != 0) return error.Failed;
        break :r app_info;
    };
    defer app_info.deinit();

    const root_menubar = r: {
        var menubar_ref : AXUIElementRef = null;
        const error_code = getMenubarRefFromPid(app_info.pid, &menubar_ref);
        if(error_code != 0) return error.Failed;
        break :r menubar_ref;
    };
    defer c.CFRelease(root_menubar);

    var ref: AXUIElementRef = null;
    var todoRelease: CFArrayRef = null;
    defer if(todoRelease != null) c.CFRelease(todoRelease);
    for(menu_list.items,0..)|menu_name,i| {
        if(i == 0) {
            const items,const len = r:{
                var menu_items: CFArrayRef = undefined;
                var len: c_int = undefined;
                const error_code = getChildren(root_menubar,  &menu_items, &len);
                if(error_code != 0) return error.Failed;
                break :r .{menu_items,len};
            };
            todoRelease = items;
            ref = for(0..@intCast(len))|m_i|{
                var item = l:{
                    var item: ValueItem = undefined;
                    const error_code = getValueAtIndex(items, @intCast(m_i), &item);
                    if(error_code != 0) return error.Failed;
                    // std.debug.print("{s}={s}\n", .{item.name,menu_name});
                    break :l item;
                };
                defer item.deinit();
                if(std.mem.eql(u8, menu_name, std.mem.span(item.name))) {
                    break item.ref;
                }
            } else return error.Ohno;
            continue;
        }
        // std.debug.print("ref={?}\n", .{ref});
        const ref_items, _ = r:{
            var menu_items: CFArrayRef = undefined;
            var len: c_int = undefined;
            const error_code = getChildren(ref,  &menu_items, &len);
            if(error_code != 0) return error.FailedChild;
            break :r .{menu_items,len};
        };
        c.CFRelease(todoRelease);
        todoRelease = ref_items;
        var first_item = l:{
            var item: ValueItem = undefined;
            const error_code = getValueAtIndex(ref_items, 0, &item);
            if(error_code != 0) return error.Failed;
            break :l item;
        };
        defer first_item.deinit();
        const items, const len = r:{
            var menu_items: CFArrayRef = undefined;
            var len: c_int = undefined;
            const error_code = getChildren(first_item.ref,  &menu_items, &len);
            if(error_code != 0) return error.FailedChild;
            break :r .{menu_items,len};
        };
        c.CFRelease(todoRelease);
        todoRelease = items;
        ref = for(0..@intCast(len))|m_i|{
            var item = l:{
                var item: ValueItem = undefined;
                const error_code = getValueAtIndex(items, @intCast(m_i), &item);
                if(error_code != 0) return error.Failed;
                // std.debug.print("{s}={s}\n", .{item.name,menu_name});
                break :l item;
            };
            defer item.deinit();
            if(std.mem.eql(u8, menu_name, std.mem.span(item.name))) {
                break item.ref;
            }
        } else return error.Ohno;
        if(i == menu_list.items.len - 1) {
            const err = clickUIElement(ref);
            if(err != 0) {
                std.debug.print("点击菜单失败 {s}", .{menu_name});
                return error.FailedClickUIELement;
            }
        }

    }
}
// const menu_script = @embedFile("./osascript/menu.js");
// fn clickMenu(menu_path: [] const u8) !void {
//     const allocator = std.heap.page_allocator;
//     const args = [_][]const u8{"osascript","-l","JavaScript"};
//     var child = std.process.Child.init(&args,allocator);
//     child.stdin_behavior = .Pipe;
//     child.stdout_behavior = .Ignore;
//     child.stderr_behavior = .Pipe;
//     try child.spawn();
//     const menu_path_trimed = try trimPerItem(allocator, menu_path);
//     defer allocator.free(menu_path_trimed);
//     const code = try std.mem.replaceOwned(u8, allocator, menu_script,
//     \\$menu_path
//     ,
//     menu_path_trimed);
//     defer allocator.free(code);
//     if(child.stdin) |the_stdin| { 
//         defer the_stdin.close();
//         try the_stdin.writeAll(code);
//     }
//     if(child.stderr) |the_stderr| {
//         defer the_stderr.close();
//         var result: [1] u8 = undefined;
//         _ = try the_stderr.read(&result);
//         if(result[0] != '0') {
//             std.debug.print("Failed to performance {s} \n", .{menu_path});
//         }
//         // std.debug.print("len_read={},result={s}\n", .{len_read,&result});
//     }
// }

const AppInfo = extern struct {
    ref: ?*opaque {} = null,     // 前台应用的引用
    pid: c_int,           // 进程 ID int类型
    name: [*:0] const u8, // 应用名称（C 字符串）

    pub fn deinit(self: *@This()) void {
        std.c.free(@ptrCast(@constCast(self.name)));
    }
    pub fn format(self: @This(),comptime fmt: [] const u8,options: std.fmt.FormatOptions,writer:anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("AppInfo{{.ref={?},.pid={},.name=\"{s}\"}}",.{
            self.ref,
            self.pid,
            self.name
        });
    }
};
const ValueItem = extern struct {
    ref: AXUIElementRef = null,   
    name: [*:0] const u8, // 应用名称（C 字符串）

    pub fn deinit(self: *@This()) void {
        std.c.free(@ptrCast(@constCast(self.name)));
        // c.CFRelease(self.ref);
    }
    pub fn format(self: @This(),comptime fmt: [] const u8,options: std.fmt.FormatOptions,writer:anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("ValueItem{{.ref={?},.name=\"{s}\"}}",.{
            self.ref,
            self.name
        });
    }
};
extern fn frontmostApplication(out_info: *AppInfo) c_uint;
const AXUIElementRef = ?*opaque {};
extern fn getMenubarRefFromPid(pid: c_int, out_menubar: *AXUIElementRef) c_uint;
const CFArrayRef = ?*opaque {};
extern fn getChildren(ref: AXUIElementRef,out_array: *CFArrayRef,len: *c_int) c_uint;
extern fn getValueAtIndex(array:CFArrayRef,i:c_int,out: *ValueItem) c_uint;
extern fn clickUIElement(ref: AXUIElementRef)  c_uint;

/// 将 `Window -> Move & Resize -> Left` 转为 List
/// 也就是去掉每一项前后空格
/// 需要用到Allocator
fn menuPath2list(allocator: std.mem.Allocator,str: [] const u8) !std.ArrayList([] const u8) {
    // 这里返回的是一个Iterator
    // 为什么是Iterator ?
    // 这样做为了避免Allocator
    var iter = std.mem.splitSequence(u8, str, "->");
    // 使用一个List 存储起来
    var list: std.ArrayList([] const u8) = .empty;

    // 因为next函数传入的是一个指针，所以const大概率是会报错的，保险起见使用var
    while(iter.next())|item| {
        const item_trimed = std.mem.trim(u8, item, " ");
        try list.append(allocator,item_trimed);
    }
    return list;
}
test menuPath2list {
    const allocator = std.testing.allocator;
    const list = try menuPath2list(allocator, "a->b ->c");
    defer list.deinit();
    try std.testing.expectEqual(list.items.len, 3);
    try std.testing.expectEqualDeep(list.items[0], "a");
    try std.testing.expectEqualDeep(list.items[2], "c");
}
fn errorCode(code: c_uint) !void {
    if(code != 0) return error.Failed;
}
test "go" {
    const allocator = std.heap.page_allocator;
    _ = allocator;
    // const error_code = clickMenu("Window  -> Move & Resize -> Left & Right");
    var app_info:AppInfo = undefined;
    var error_code = frontmostApplication(&app_info);
    if(error_code != 0) return error.Failed;
    defer app_info.deinit();
    std.debug.print("{}\n", .{app_info});
    var menubar_ref : AXUIElementRef = null;
    error_code = getMenubarRefFromPid(app_info.pid, &menubar_ref);
    if(error_code != 0) return error.Failed;
    defer c.CFRelease(menubar_ref);
    std.debug.print("menubar={?}\n", .{menubar_ref});

    var menu_items: CFArrayRef = undefined;
    var len: c_int = undefined;
    error_code = getChildren(menubar_ref,  &menu_items, &len);
    if(error_code != 0) return error.Failed;
    // defer if(menu_items != null) c.CFRelease(menu_items);
    std.debug.print("len={},menu_items={?}\n", .{len,menu_items});
    for(0..@intCast(len))|i| {
        var item: ValueItem = undefined;
        defer item.deinit();
        error_code = getValueAtIndex(menu_items, @intCast(i), &item);
        if(error_code != 0) return error.Failed;
        std.debug.print("item={}\nChildren:\n\n", .{item});
        var menu_items_child: CFArrayRef = undefined;
        var len_child: c_int = undefined;
        error_code = getChildren(item.ref,  &menu_items_child, &len_child);
        if(error_code != 0) return error.Failed;
        // defer c.CFRelease(menu_items_child);
        std.debug.print("len_child={},menu_items_child={?}\n", .{len_child,menu_items_child}); 
        var item_child: ValueItem = undefined;
        error_code = getValueAtIndex(menu_items_child, 0, &item_child);
        if(error_code != 0) return error.Failed;    
        defer item_child.deinit();
        std.debug.print("{}\n", .{item_child});
        {
            const array,const array_len = r:{
                var array: CFArrayRef = undefined;
                var array_len: c_int = undefined;
                error_code = getChildren(item_child.ref,  &array, &array_len);
                if(error_code != 0) return error.Failed;
                break :r .{array,array_len};
            };
            std.debug.print("array={?},array_len={}\n", .{array,array_len});
            {
                for(0..@intCast(array_len))|c_i| {
                    var item_child_2: ValueItem = undefined;
                    error_code = getValueAtIndex(array, @intCast(c_i), &item_child_2);
                    if(error_code != 0) return error.Failed;    
                    defer item_child.deinit();
                    std.debug.print("item_child_2={?}\n", .{item_child_2});
                }
            }
        }
    }

    // Very good
    // const result = try trimPerItem(allocator, "Window  -> Move & Resize -> Left & Right  ");
    // std.debug.print("{s}\n", .{result});
    // try clickMenu(result);
    
    // const a = if(true) 10 else 100;
    // _=a;
}