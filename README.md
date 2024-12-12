# capslang - CapsLock to switch keyboard layout in Windows

This small windowless program allow you swich keyboard layout with CapsLock key. While non-standard keyboard layout will bright Scroll Lock indicator. Usual Caps Lock function available via Shift + CapsLock key combination. I recommend set "To turn off Caps Lock -- SHIFT key" in Windows Advanced Key Settings.

Initially forked from [here](http://flydom.ru/capslang)

## Complation

Just run `make build-release` to compile it. Binary will be in `zig-out/bin` folder.

## Installation

### Option 1 (Recommended)

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

### Option 2 (Old way)
Copy capslang.exe to your Startup (%AppData%\Microsoft\Windows\Start Menu\Programs\Startup) folder.

*There is drawback* - it will not work in application ran with Administrator privileges.

## Run
Just run capslang.exe and enjoy

## Exit
To close programm press Ctrl + Alt + L
