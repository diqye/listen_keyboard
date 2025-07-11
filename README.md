## 编译 或 下载
```shell
zig build
```
[点我下载exe](https://github.com/diqye/listen_keyboard/releases/download/v0.0.2/listen_keyboard)

清除`MacOS`限制
```shell
xattr -d com.apple.quarantine listen_keyboard
```

## 使用

使用快捷键切换至`App`,如果当前`App`已经是要切换的了，则溯源到上一个活跃窗口.

```shell
 监听系统级别全局按键，用于显示在屏幕上，打开App
 配置文件 $HOME/.config/listen_keyboard/config
 listen_keyboard [Options]
 --verbose  显示日志
 --key_text 将按键显示在屏幕最上方
 --help     显示帮助
```

守护进程
```shell
bunx --no-install pm2 start ./zig-out/bin/listen_keyboard
```

## 配置文件

`$HOME/.config/listen_keyboard/config`

``` shell
# 这里是注释
# 
# 快捷键顺序 ⌘⇧⌥⌃, 修饰键必须按照这个顺序写。
# //  = [_]Task{

# 打开Google
Press ⌘⌃g open /Applications/Google Chrome.app
Press ⌘⌃c open /Applications/Visual Studio Code.app
Press ⌘⌃a open /Applications/QQ.app
Press ⌘⌃w open /Applications/WeChat.app
# 飞书
Press ⌘⌃f open /Applications/Lark.app
# Terminal
Press ⌘⌃t open /Applications/Ghostty.app

```