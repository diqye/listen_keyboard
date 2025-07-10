// show_text.h
#ifndef SHOW_TEXT_H
#define SHOW_TEXT_H

void init_cocoa_app(void);
void show_text_for_duration(const char *utf8_text, int seconds);

/// 获取系统风格快捷键字符串，如：⌘⇧Z、⌥<Space>、A
/// - 参数: event — 来自 macOS Quartz 的 CGEventRef
/// - 返回值: 返回一个 malloc 分配的 UTF-8 字符串（你需要调用 free() 释放）
/// - 注意: 修饰键使用 macOS 系统符号（⌘⇧⌥⌃）
///         其他键用大写字母表示，不能识别的用 <KEYNAME> 形式（如 <Space>, <Return>）
char *key_string_from_CGEvent(CGEventRef event);
#endif
