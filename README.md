# listen_keyboard
1. 快捷键 -> App
2. 快捷键 -> 菜单

<div>
    <video src="./asserts/readme_showcase.mp4" mute autoplay controls />
</div>

## 安装
两种方式，1. clone到本地编译； 2. 直接下载exe
### 编译
```shell
zig build
```
### 下载
[下载exe](https://github.com/diqye/listen_keyboard/releases/latest)

清除`MacOS`限制
```shell
xattr -d com.apple.quarantine listen_keyboard
```

## 使用

使用快捷键切换至`App`,如果当前`App`已经是要切换的了，则溯源到上一个活跃窗口.

```shell
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
# 顺序 ⌘⇧⌥⌃, 修饰键必须按照这个顺序写。

# 打开Google
Press ⌘⌃g to open /Applications/Google Chrome.app
Press ⌘⌃c to open /Applications/Visual Studio Code.app
Press ⌘⌃a to open /Applications/QQ.app
Press ⌘⌃w to open /Applications/WeChat.app
# 飞书
Press ⌘⌃f to open /Applications/Lark.app
# Terminal
Press ⌘⌃t to open /Applications/Ghostty.app

# 点击菜单
Press ⌘⌃1 to click Window  -> Move & Resize -> Left
Press ⌘⌃9 to click Window  -> Move & Resize -> Right
Press ⌘⌃5 to click Window  -> Center
Press ⌘⌃6 to click Window  -> Move & Resize -> Left & Right
# Press ⌘⌃0 to click Window  -> Move & Resize -> Quarters
Press ⌘⌃= to click Window  -> Zoom


```
