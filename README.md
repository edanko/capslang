# capslang - CapsLock to switch keyboard layout in Windows

This small windowless program allow you swich keyboard layout with CapsLock key. While non-standard keyboard layout will bright Scroll Lock indicator. Usual Caps Lock function available via Shift + CapsLock key combination. I recommend set "To turn off Caps Lock -- SHIFT key" in Windows Advanced Key Settings.

Forked from [capslang](http://flydom.ru/capslang).

---

## Quick Install

```powershell
irm https://raw.githubusercontent.com/edanko/capslang/main/install.ps1 | iex
```

### Options

```powershell
# Scheduled task (default, runs with admin privileges)
irm https://raw.githubusercontent.com/edanko/capslang/main/install.ps1 | iex

# Startup folder (no admin required)
irm https://raw.githubusercontent.com/edanko/capslang/main/install.ps1 | iex -Args "-m 1"

# Quiet mode (no prompts)
irm https://raw.githubusercontent.com/edanko/capslang/main/install.ps1 | iex -Args "-q"
```

<details>
<summary><strong>Other options</strong></summary>

### Manual Installation

1. Download [capslang-windows-x86_64.zip](https://github.com/edanko/capslang/releases/latest)
2. Extract `capslang.exe`
3. Place it in `%LOCALAPPDATA%\capslang\capslang.exe`

#### Option A: Scheduled Task

- Runs with highest privileges
- Works in all applications (including admin apps)

```cmd
schtasks /create /tn CapsLang /sc ONLOGON /tr "%LOCALAPPDATA%\capslang\capslang.exe" /rl HIGHEST /delay 0000:30 /f
```

Or via GUI:

1. Open Task Scheduler (taskschd.msc)
2. Click "Create Basic Task"
3. Name it "CapsLang" and click Next
4. Select "When I log on" and click Next
5. Select "Start a program" and click Next
6. Browse to capslang.exe location and click Next
7. Check "Open the Properties dialog for this task when I click Finish" checkbox
8. Click Finish
9. In Properties dialog, check "Run with highest privileges" checkbox
10. Click OK
11. Right-click the task and select "Run" to start it immediately

#### Option B: Startup Folder (Shortcut)

- No admin required
- Runs when you log in
- Limited to your user account

```powershell
$target = "$env:LOCALAPPDATA\capslang\capslang.exe"
$shortcut = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\CapsLang.lnk"
$ws = (New-Object -ComObject WScript.Shell).CreateShortcut($shortcut)
$ws.TargetPath = $target
$ws.WorkingDirectory = "$env:LOCALAPPDATA\capslang"
$ws.Save()
```

Or you can copy the capslang.exe to your Startup (%AppData%\Microsoft\Windows\Start Menu\Programs\Startup) folder.

</details>

---

## Uninstallation

```powershell
irm https://raw.githubusercontent.com/edanko/capslang/main/uninstall.ps1 | iex
```

<details>
<summary><strong>Other options</strong></summary>

### Manual

```cmd
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\CapsLang.lnk"
schtasks /Delete /TN "CapsLang" /F
rmdir /s /q "%LOCALAPPDATA%\capslang"
```

</details>

---

## Usage

| Action          | Key              |
| --------------- | ---------------- |
| Switch layout   | CapsLock         |
| Normal CapsLock | Shift + CapsLock |
| Exit program    | Ctrl + Alt + L   |

---

## Building from Source

Just run `make build-release` to compile it. Binary will be in `zig-out/bin` folder.

---

## License

GNU GPL v3
