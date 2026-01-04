const std = @import("std");
const windows = std.os.windows;

pub const APP_NAME = "CapsLang";
pub const BUFFER_SIZE = 128;
pub const EXIT_KEY = 'L';

const W = windows;

pub const HWND = W.HWND;
pub const HHOOK = *anyopaque;
pub const HKL = *anyopaque;
pub const HMODULE = *anyopaque;
pub const WPARAM = W.WPARAM;
pub const LPARAM = W.LPARAM;
pub const LRESULT = W.LRESULT;

pub const HOOKPROC = *const fn (code: i32, wParam: WPARAM, lParam: LPARAM) callconv(.winapi) LRESULT;

pub const Messages = struct {
    pub const INPUT_LANG_CHANGED = 0x0050;
    pub const KEYDOWN = 0x0100;
    pub const HOTKEY = 0x0312;
};

pub const VirtualKeys = struct {
    pub const CAPITAL = 0x14;
    pub const SHIFT = 0x10;
};

pub const HookId = struct {
    pub const KEYBOARD_LL = 13;
    pub const EXIT = 33;
};

pub const Modifier = struct {
    pub const CONTROL = 0x0002;
    pub const ALT = 0x0001;
};

pub const Flags = struct {
    pub const TRUE: i32 = 1;
    pub const FALSE: i32 = 0;
    pub const ERROR_EXISTS = 183;
    pub const HC_ACTION = 0;
};

pub const MessageBox = struct {
    pub const OK = 0x00000000;
    pub const ICON_ERROR = 0x00000010;
};

pub const Hkl = struct {
    pub const NEXT = @as(HKL, @ptrFromInt(1));
};

pub const MSG = extern struct {
    hwnd: ?HWND,
    message: u32,
    wParam: WPARAM,
    lParam: LPARAM,
    time: u32,
    pt: extern struct {
        x: i32,
        y: i32,
    },
    lPrivate: u32,
};

pub const KBDLLHOOKSTRUCT = extern struct {
    vkCode: u32,
    scanCode: u32,
    flags: u32,
    time: u32,
    dwExtraInfo: u32,
};

const User32Api = struct {
    extern "user32" fn GetForegroundWindow() callconv(.winapi) ?HWND;
    extern "user32" fn CallNextHookEx(hhk: ?HHOOK, nCode: i32, wParam: WPARAM, lParam: LPARAM) callconv(.winapi) LRESULT;
    extern "user32" fn GetKeyState(nVirtKey: i32) callconv(.winapi) i16;
    extern "user32" fn PostMessageW(hWnd: ?HWND, msg: u32, wParam: WPARAM, lParam: LPARAM) callconv(.winapi) i32;
    extern "user32" fn MessageBoxW(hWnd: ?HWND, lpText: [*:0]const u16, lpCaption: [*:0]const u16, uType: u32) callconv(.winapi) i32;
    extern "user32" fn GetKeyboardLayout(idThread: u32) callconv(.winapi) HKL;
    extern "user32" fn RegisterHotKey(hWnd: ?HWND, id: i32, fsModifiers: u32, vk: u32) callconv(.winapi) i32;
    extern "user32" fn SetWindowsHookExW(idHook: i32, lpfn: HOOKPROC, hmod: ?HMODULE, dwThreadId: u32) callconv(.winapi) ?HHOOK;
    extern "user32" fn UnhookWindowsHookEx(hhk: HHOOK) callconv(.winapi) i32;
    extern "user32" fn GetMessageW(lpMsg: *MSG, hWnd: ?HWND, wMsgFilterMin: u32, wMsgFilterMax: u32) callconv(.winapi) i32;
    extern "user32" fn TranslateMessage(lpMsg: *const MSG) callconv(.winapi) i32;
    extern "user32" fn DispatchMessageW(lpMsg: *const MSG) callconv(.winapi) LRESULT;
    extern "user32" fn PostQuitMessage(nExitCode: i32) callconv(.winapi) void;
};

const Kernel32Api = struct {
    extern "kernel32" fn CreateEventW(lpEventAttributes: ?*anyopaque, bManualReset: i32, bInitialState: i32, lpName: [*:0]const u16) callconv(.winapi) ?*anyopaque;
    extern "kernel32" fn CloseHandle(hObject: *anyopaque) callconv(.winapi) i32;
    extern "kernel32" fn GetLastError() callconv(.winapi) u32;
    extern "kernel32" fn GetModuleHandleW(lpModuleName: ?[*:0]const u16) callconv(.winapi) ?HMODULE;
    extern "kernel32" fn ExitProcess(uExitCode: u32) callconv(.winapi) noreturn;
};

pub const CapsLangError = error{
    CreateEventFailed,
    AlreadyRunning,
    RegisterHotkeyFailed,
    SetHookFailed,
};

pub const ErrorMessages = struct {
    pub const CreateEventFailed = "Failed to create event";
    pub const AlreadyRunning = "CapsLang is already running!";
    pub const RegisterHotkeyFailed = "Failed to register hotkey";
    pub const SetHookFailed = "Failed to install keyboard hook";
};

fn toUtf16Le(input: []const u8, buffer: *[BUFFER_SIZE:0]u16) !usize {
    const len = try std.unicode.utf8ToUtf16Le(buffer, input);
    buffer[len] = 0;
    return len;
}

pub const Window = struct {
    pub fn getForeground() ?HWND {
        return User32Api.GetForegroundWindow();
    }

    pub fn postMessage(hwnd: HWND, msg: u32, wparam: WPARAM, lparam: LPARAM) bool {
        return User32Api.PostMessageW(hwnd, msg, wparam, lparam) != 0;
    }

    pub fn showError(title: []const u8, message: []const u8) void {
        var title_buf: [BUFFER_SIZE:0]u16 = undefined;
        var message_buf: [BUFFER_SIZE:0]u16 = undefined;

        _ = toUtf16Le(title, &title_buf) catch return;
        _ = toUtf16Le(message, &message_buf) catch return;

        _ = User32Api.MessageBoxW(
            null,
            &message_buf,
            &title_buf,
            MessageBox.OK | MessageBox.ICON_ERROR,
        );
    }
};

pub const Keyboard = struct {
    pub fn isShiftPressed() bool {
        return User32Api.GetKeyState(VirtualKeys.SHIFT) < 0;
    }

    pub fn currentLayout() HKL {
        return User32Api.GetKeyboardLayout(0);
    }

    pub fn switchLayout(hwnd: HWND) bool {
        return Window.postMessage(
            hwnd,
            Messages.INPUT_LANG_CHANGED,
            0,
            @intFromPtr(Hkl.NEXT),
        );
    }
};

pub const MessageLoop = struct {
    msg: MSG,

    pub fn init() MessageLoop {
        return .{ .msg = undefined };
    }

    pub fn run(self: *MessageLoop) void {
        while (User32Api.GetMessageW(&self.msg, null, 0, 0) != 0) {
            _ = User32Api.TranslateMessage(&self.msg);
            if (self.isExitMessage()) {
                User32Api.PostQuitMessage(0);
            }
            _ = User32Api.DispatchMessageW(&self.msg);
        }
    }

    fn isExitMessage(self: *const MessageLoop) bool {
        return self.msg.message == Messages.HOTKEY and
            self.msg.wParam == HookId.EXIT;
    }
};

pub const KeyboardHook = struct {
    handle: ?HHOOK,

    pub fn init() !KeyboardHook {
        const handle = User32Api.SetWindowsHookExW(
            HookId.KEYBOARD_LL,
            keyboardHookProc,
            Kernel32Api.GetModuleHandleW(null),
            0,
        );

        if (handle == null) {
            return CapsLangError.SetHookFailed;
        }

        return KeyboardHook{ .handle = handle };
    }

    pub fn deinit(self: *const KeyboardHook) void {
        if (self.handle) |h| {
            _ = User32Api.UnhookWindowsHookEx(h);
        }
    }
};

pub const AppContext = struct {
    hook: ?HHOOK = null,
    exitEvent: ?*anyopaque = null,

    pub fn init() !AppContext {
        var ctx = AppContext{};
        try ctx.ensureSingleInstance();
        return ctx;
    }

    pub fn deinit(self: *AppContext) void {
        if (self.exitEvent) |e| {
            _ = Kernel32Api.CloseHandle(e);
        }
        if (self.hook) |h| {
            _ = User32Api.UnhookWindowsHookEx(h);
        }
    }

    fn ensureSingleInstance(self: *AppContext) !void {
        var event_name_buf: [BUFFER_SIZE:0]u16 = undefined;
        _ = toUtf16Le(APP_NAME, &event_name_buf) catch {};

        self.exitEvent = Kernel32Api.CreateEventW(
            null,
            Flags.TRUE,
            Flags.FALSE,
            &event_name_buf,
        );

        if (self.exitEvent == null) {
            return CapsLangError.CreateEventFailed;
        }

        if (Kernel32Api.GetLastError() == Flags.ERROR_EXISTS) {
            return CapsLangError.AlreadyRunning;
        }
    }

    fn setHook(self: *AppContext, hook: KeyboardHook) void {
        self.hook = hook.handle;
    }
};

export fn keyboardHookProc(nCode: i32, wParam: WPARAM, lParam: LPARAM) callconv(.winapi) LRESULT {
    if (nCode < 0) {
        return User32Api.CallNextHookEx(null, nCode, wParam, lParam);
    }

    if (nCode == Flags.HC_ACTION) {
        const ks = @as(*KBDLLHOOKSTRUCT, @ptrFromInt(@as(usize, @intCast(lParam))));
        if (ks.vkCode == VirtualKeys.CAPITAL and !Keyboard.isShiftPressed()) {
            if (wParam == Messages.KEYDOWN) {
                if (Window.getForeground()) |hwnd| {
                    _ = Keyboard.switchLayout(hwnd);
                    return Flags.TRUE;
                }
            }
        }
    }

    return User32Api.CallNextHookEx(null, nCode, wParam, lParam);
}

fn showErrorAndExit(err: CapsLangError) noreturn {
    const message = switch (err) {
        CapsLangError.CreateEventFailed => ErrorMessages.CreateEventFailed,
        CapsLangError.AlreadyRunning => ErrorMessages.AlreadyRunning,
        CapsLangError.RegisterHotkeyFailed => ErrorMessages.RegisterHotkeyFailed,
        CapsLangError.SetHookFailed => ErrorMessages.SetHookFailed,
    };
    Window.showError("CapsLang - Error", message);
    Kernel32Api.ExitProcess(1);
}

pub fn main() !void {
    var app = AppContext.init() catch |err| {
        showErrorAndExit(err);
    };
    defer app.deinit();

    _ = Keyboard.currentLayout();

    if (User32Api.RegisterHotKey(
        null,
        HookId.EXIT,
        Modifier.CONTROL | Modifier.ALT,
        EXIT_KEY,
    ) == 0) {
        showErrorAndExit(CapsLangError.RegisterHotkeyFailed);
    }

    const hook = KeyboardHook.init() catch |err| {
        showErrorAndExit(err);
    };
    app.setHook(hook);

    var message_loop = MessageLoop.init();
    message_loop.run();
}
