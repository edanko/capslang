const std = @import("std");
const windows = std.os.windows;
const WINAPI = windows.WINAPI;

// Windows types
const WindowsTypes = struct {
    const HANDLE = windows.HANDLE;
    const HWND = windows.HWND;
    const HHOOK = *anyopaque;
    const HKL = *anyopaque;
    const HMODULE = *anyopaque;
    const WPARAM = windows.WPARAM;
    const LPARAM = windows.LPARAM;
    const LRESULT = windows.LRESULT;
    const HOOKPROC = *const fn (code: i32, wParam: WPARAM, lParam: LPARAM) callconv(WINAPI) LRESULT;
};

// Windows constants
const WindowsConstants = struct {
    const WH_KEYBOARD_LL = 13;
    const EXIT = 33;
    const VK_CAPITAL = 0x14;
    const VK_SHIFT = 0x10;
    const HKL_NEXT = @as(WindowsTypes.HKL, @ptrFromInt(1));
    const WM_INPUTLANGCHANGEREQUEST = 0x0050;
    const WM_KEYDOWN = 0x0100;
    const WM_HOTKEY = 0x0312;
    const MB_OK = 0x00000000;
    const MB_ICONERROR = 0x00000010;
    const MOD_CONTROL = 0x0002;
    const MOD_ALT = 0x0001;
    const TRUE = 1;
    const FALSE = 0;
    const ERROR_ALREADY_EXISTS = 183;
    const HC_ACTION = 0;
};

// Windows structures
const MSG = extern struct {
    hwnd: ?WindowsTypes.HWND,
    message: u32,
    wParam: WindowsTypes.WPARAM,
    lParam: WindowsTypes.LPARAM,
    time: u32,
    pt: extern struct {
        x: i32,
        y: i32,
    },
    lPrivate: u32,
};

const KBDLLHOOKSTRUCT = extern struct {
    vkCode: u32,
    scanCode: u32,
    flags: u32,
    time: u32,
    dwExtraInfo: u32,
};

// Windows API bindings
const WindowsAPI = struct {
    const user32 = struct {
        extern "user32" fn GetForegroundWindow() callconv(WINAPI) ?WindowsTypes.HWND;
        extern "user32" fn CallNextHookEx(hhk: ?WindowsTypes.HHOOK, nCode: i32, wParam: WindowsTypes.WPARAM, lParam: WindowsTypes.LPARAM) callconv(WINAPI) WindowsTypes.LRESULT;
        extern "user32" fn GetKeyState(nVirtKey: i32) callconv(WINAPI) i16;
        extern "user32" fn PostMessageW(hWnd: ?WindowsTypes.HWND, msg: u32, wParam: WindowsTypes.WPARAM, lParam: WindowsTypes.LPARAM) callconv(WINAPI) i32;
        extern "user32" fn MessageBoxW(hWnd: ?WindowsTypes.HWND, lpText: [*:0]const u16, lpCaption: [*:0]const u16, uType: u32) callconv(WINAPI) i32;
        extern "user32" fn GetKeyboardLayout(idThread: u32) callconv(WINAPI) WindowsTypes.HKL;
        extern "user32" fn RegisterHotKey(hWnd: ?WindowsTypes.HWND, id: i32, fsModifiers: u32, vk: u32) callconv(WINAPI) i32;
        extern "user32" fn SetWindowsHookExW(idHook: i32, lpfn: WindowsTypes.HOOKPROC, hmod: ?WindowsTypes.HMODULE, dwThreadId: u32) callconv(WINAPI) ?WindowsTypes.HHOOK;
        extern "user32" fn UnhookWindowsHookEx(hhk: WindowsTypes.HHOOK) callconv(WINAPI) i32;
        extern "user32" fn GetMessageW(lpMsg: *MSG, hWnd: ?WindowsTypes.HWND, wMsgFilterMin: u32, wMsgFilterMax: u32) callconv(WINAPI) i32;
        extern "user32" fn TranslateMessage(lpMsg: *const MSG) callconv(WINAPI) i32;
        extern "user32" fn DispatchMessageW(lpMsg: *const MSG) callconv(WINAPI) WindowsTypes.LRESULT;
        extern "user32" fn PostQuitMessage(nExitCode: i32) callconv(WINAPI) void;
    };

    const kernel32 = struct {
        extern "kernel32" fn CreateEventW(lpEventAttributes: ?*anyopaque, bManualReset: i32, bInitialState: i32, lpName: [*:0]const u16) callconv(WINAPI) ?WindowsTypes.HANDLE;
        extern "kernel32" fn CloseHandle(hObject: WindowsTypes.HANDLE) callconv(WINAPI) i32;
        extern "kernel32" fn GetLastError() callconv(WINAPI) u32;
        extern "kernel32" fn GetModuleHandleW(lpModuleName: ?[*:0]const u16) callconv(WINAPI) ?WindowsTypes.HMODULE;
        extern "kernel32" fn ExitProcess(uExitCode: u32) callconv(WINAPI) noreturn;
    };
};

// Application state
const AppState = struct {
    var caps_default: WindowsTypes.HKL = undefined;
    var caps_khook: ?WindowsTypes.HHOOK = undefined;
    var caps_hEvent: ?WindowsTypes.HANDLE = undefined;
    var caps_key: u32 = WindowsConstants.VK_CAPITAL;
};

// Add configuration constants
const Config = struct {
    const APP_NAME = "CapsLang";
    const BUFFER_SIZE = 128;
    const EXIT_KEY = 'L';
};

// Create a dedicated UTF16 converter
const Utf16Converter = struct {
    fn convert(text: []const u8, buffer: *[Config.BUFFER_SIZE:0]u16) !usize {
        const len = try std.unicode.utf8ToUtf16Le(buffer, text);
        buffer[len] = 0;
        return len;
    }
};

// Create a dedicated Window struct for window-related operations
const Window = struct {
    fn getForeground() ?WindowsTypes.HWND {
        return WindowsAPI.user32.GetForegroundWindow();
    }

    fn postMessage(hwnd: WindowsTypes.HWND, msg: u32, wparam: WindowsTypes.WPARAM, lparam: WindowsTypes.LPARAM) bool {
        return WindowsAPI.user32.PostMessageW(hwnd, msg, wparam, lparam) != 0;
    }

    fn showError(caption: []const u8, text: []const u8) void {
        var caption_buf: [Config.BUFFER_SIZE:0]u16 = undefined;
        var text_buf: [Config.BUFFER_SIZE:0]u16 = undefined;

        Utf16Converter.convert(caption, &caption_buf) catch return;
        Utf16Converter.convert(text, &text_buf) catch return;

        _ = WindowsAPI.user32.MessageBoxW(null, &text_buf, &caption_buf, WindowsConstants.MB_OK | WindowsConstants.MB_ICONERROR);
    }
};

// Create a dedicated KeyboardState struct
const KeyboardState = struct {
    fn isShiftPressed() bool {
        return WindowsAPI.user32.GetKeyState(WindowsConstants.VK_SHIFT) < 0;
    }

    fn getCurrentLayout() WindowsTypes.HKL {
        return WindowsAPI.user32.GetKeyboardLayout(0);
    }
};

// Create a dedicated Error type
const CapsLangError = error{
    CreateEventFailed,
    AlreadyRunning,
    RegisterHotkeyFailed,
    SetHookFailed,
};

// Create a dedicated MessageHandler struct
const MessageHandler = struct {
    msg: MSG,

    fn init() MessageHandler {
        return .{ .msg = undefined };
    }

    fn processMessages(self: *MessageHandler) void {
        while (WindowsAPI.user32.GetMessageW(&self.msg, null, 0, 0) != 0) {
            _ = WindowsAPI.user32.TranslateMessage(&self.msg);
            if (self.isExitHotkey()) {
                WindowsAPI.user32.PostQuitMessage(0);
            }
            _ = WindowsAPI.user32.DispatchMessageW(&self.msg);
        }
    }

    fn isExitHotkey(self: *const MessageHandler) bool {
        return self.msg.message == WindowsConstants.WM_HOTKEY and
            self.msg.wParam == WindowsConstants.EXIT;
    }
};

// Create a dedicated KeyboardHook struct
const KeyboardHook = struct {
    hook: ?WindowsTypes.HHOOK,

    fn init() !KeyboardHook {
        const hook = WindowsAPI.user32.SetWindowsHookExW(
            WindowsConstants.WH_KEYBOARD_LL,
            KbdHook,
            WindowsAPI.kernel32.GetModuleHandleW(null),
            0,
        );

        if (hook == null) {
            return CapsLangError.SetHookFailed;
        }

        return KeyboardHook{ .hook = hook };
    }

    fn deinit(self: *const KeyboardHook) void {
        if (self.hook) |h| {
            _ = WindowsAPI.user32.UnhookWindowsHookEx(h);
        }
    }
};

// Update KbdHook to use the new structs
export fn KbdHook(nCode: i32, wParam: WindowsTypes.WPARAM, lParam: WindowsTypes.LPARAM) callconv(WINAPI) WindowsTypes.LRESULT {
    if (nCode < 0) {
        return WindowsAPI.user32.CallNextHookEx(AppState.caps_khook, nCode, wParam, lParam);
    }

    if (nCode == WindowsConstants.HC_ACTION) {
        const ks = @as(*KBDLLHOOKSTRUCT, @ptrFromInt(@as(usize, @intCast(lParam))));
        if (ks.vkCode == AppState.caps_key and !KeyboardState.isShiftPressed()) {
            if (wParam == WindowsConstants.WM_KEYDOWN) {
                if (Window.getForeground()) |hWnd| {
                    _ = Window.postMessage(hWnd, WindowsConstants.WM_INPUTLANGCHANGEREQUEST, 0, @intFromPtr(WindowsConstants.HKL_NEXT));
                    return WindowsConstants.TRUE;
                }
            }
        }
    }

    return WindowsAPI.user32.CallNextHookEx(AppState.caps_khook, nCode, wParam, lParam);
}

// Update initializeSingleInstance to use the new structs
fn initializeSingleInstance() !void {
    var event_name_buf: [Config.BUFFER_SIZE:0]u16 = undefined;
    _ = try Utf16Converter.convert(Config.APP_NAME, &event_name_buf);

    AppState.caps_hEvent = WindowsAPI.kernel32.CreateEventW(null, WindowsConstants.TRUE, WindowsConstants.FALSE, &event_name_buf);

    if (AppState.caps_hEvent == null) {
        return CapsLangError.CreateEventFailed;
    }

    if (WindowsAPI.kernel32.GetLastError() == WindowsConstants.ERROR_ALREADY_EXISTS) {
        return CapsLangError.AlreadyRunning;
    }
}

// Update error handling
fn exitWithError(err: CapsLangError) noreturn {
    const msg = switch (err) {
        CapsLangError.CreateEventFailed => "CreateEvent() failed",
        CapsLangError.AlreadyRunning => "CapsLang is already running!",
        CapsLangError.RegisterHotkeyFailed => "RegisterHotKey() failed",
        CapsLangError.SetHookFailed => "SetWindowsHookEx() failed",
    };
    Window.showError("CapsLang - Error", msg);
    WindowsAPI.kernel32.ExitProcess(1);
}

// Update main to use the new structs
pub fn main() !void {
    try initializeSingleInstance();
    defer _ = WindowsAPI.kernel32.CloseHandle(AppState.caps_hEvent.?);

    AppState.caps_default = KeyboardState.getCurrentLayout();

    if (WindowsAPI.user32.RegisterHotKey(null, WindowsConstants.EXIT, WindowsConstants.MOD_CONTROL | WindowsConstants.MOD_ALT, Config.EXIT_KEY) == 0) {
        return CapsLangError.RegisterHotkeyFailed;
    }

    var keyboard_hook = try KeyboardHook.init();
    defer keyboard_hook.deinit();
    AppState.caps_khook = keyboard_hook.hook;

    var message_handler = MessageHandler.init();
    message_handler.processMessages();
}
