## Source
`main.zig`

## 编译
```shell
zig build
```
## Run

守护进程
```shell
bunx pm2 start ./zig-out/bin/listen_keyboard
```
## 快捷键列表
```zig
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
```