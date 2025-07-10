#import <AppKit/AppKit.h>

const char *get_focused_app_name(void) {
    NSRunningApplication *app = [[NSWorkspace sharedWorkspace] frontmostApplication];
    if (app == nil) return NULL;

    NSURL *url = [app bundleURL];
    if( url == nil) return NULL;

    NSString *path = [url path];
    return [path UTF8String]; // 这是 autoreleased，不要保留
}

BOOL open_and_activateApp(char *path) {

    // 将C字符串转换为NSString
    NSString *appPath = @(path);
    // 创建NSURL
    NSURL *url = [NSURL fileURLWithPath:appPath isDirectory:YES];
    if (!url) {
        return NO;
    }
    
    // 获取NSWorkspace共享实例
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    if (!workspace) {
        return NO;
    }
    
    // 创建打开配置
    NSWorkspaceOpenConfiguration *config = [NSWorkspaceOpenConfiguration configuration];
    if (!config) {
        return NO;
    }
    
    // 设置激活选项
    [config setActivates:YES];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    // 打开并激活应用程序
    __block BOOL success = NO;
    [workspace  openApplicationAtURL:url
                configuration:config
                completionHandler:^(NSRunningApplication *app, NSError *error) {
                    if (error) {
                        NSLog(@"Failed to open app at %@: %@", appPath, error);
                        success = NO;
                    } else {
                        // 强制激活应用并确保获得焦点
                        BOOL activated = [app activateWithOptions:NSApplicationActivateAllWindows];
                        if (activated) {
                            // NSLog(@"Successfully activated app: %@", appPath);
                            success = YES;
                        } else {
                            NSLog(@"Failed to activate app: %@", appPath);
                            success = NO;
                        }
                    }
                    dispatch_semaphore_signal(semaphore);
    }];
    
    return success;
}