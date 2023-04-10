/*
	CapsLang by Ryurik 2003-11-12, updated 2006-10-24
	
	11-04-2023
	Updated by LWJGL2 for correct work at startup from the administrator.
	Updated by LWJGL2 для корректной работы при запуске от администратора.

	This small windowless program allow you swich keyboard layout with CapsLock key.
	While non-standard keyboard layout will bright Scroll Lock indicator

	Installation: copy capslang.exe to your Startup (Start -> Programs) folder.
	Run: Just run capslang.exe and enjoy
	Exit: To close programm press Ctrl + Alt + L
	Note: Does not work with Win9x!

	Эта программа позволяет переключать раскладку клавиатуры кнопкой CapsLock.
	Для обычного использования CapsLock следует нажать Shift+CapsLock.
	Рекомендуется установить в Windows отключение режима CapsLock клавишей Shift
	При использовании альтернативной раскладки загорается индикатор ScrollLock.
	Для выхода из программы следует нажать Ctrl + Alt + L.
	Программа предназначена для работы в операционных системах Windows 2000/XP.
 */

#define _WIN32_WINNT 0x500

#include <windows.h>
#include <tchar.h>
#include <winuser.h>

#define WH_KEYBOARD_LL     13
typedef struct tagKBDLLHOOKSTRUCT {
    DWORD   vkCode;
    DWORD   scanCode;
    DWORD   flags;
    DWORD   time;
    DWORD   dwExtraInfo;
} KBDLLHOOKSTRUCT, FAR *LPKBDLLHOOKSTRUCT, *PKBDLLHOOKSTRUCT;

#define EXIT 33

HKL		caps_default;
HHOOK	caps_khook;
HANDLE  caps_hEvent;
UINT	caps_key = VK_CAPITAL;

HWND GetFocusWindow()
{
	return GetForegroundWindow();
}

void ToggleLight() {
	keybd_event( VK_SCROLL,0,KEYEVENTF_EXTENDEDKEY | 0,0 );
	keybd_event( VK_SCROLL,0,KEYEVENTF_EXTENDEDKEY | KEYEVENTF_KEYUP,0 );
}

LRESULT CALLBACK KbdHook(int nCode,WPARAM wParam,LPARAM lParam) {
	if (nCode<0)	return CallNextHookEx(caps_khook,nCode,wParam,lParam);
	if (nCode==HC_ACTION) {
		KBDLLHOOKSTRUCT *ks=(KBDLLHOOKSTRUCT*)lParam;
		if (ks->vkCode==caps_key && (GetKeyState(VK_SHIFT)>=0)) {
			if (wParam==WM_KEYDOWN) {
				HWND hWnd=GetFocusWindow();
				if (hWnd) {
				    // ALT + SHIFT для переключения
				    keybd_event(VK_MENU, 0, 0, 0);
				    keybd_event(VK_SHIFT, 0, 0, 0);
				    keybd_event(VK_MENU, 0, KEYEVENTF_KEYUP, 0);
				    keybd_event(VK_SHIFT, 0, KEYEVENTF_KEYUP, 0);
					ToggleLight();
					return TRUE;
				}
			}
		}
	}
skip:
	return CallNextHookEx(caps_khook,nCode,wParam,lParam);
}

void  failedx(const TCHAR *msg) {
	MessageBox(NULL,msg,_T("Capslang exception"),MB_OK|MB_ICONERROR);
	ExitProcess(1);
}

void  failed(const TCHAR *msg) {
	DWORD	fm;
	TCHAR	*msg1,*msg2;
	const TCHAR	*args[2];

	fm=FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER|FORMAT_MESSAGE_FROM_SYSTEM|
 FORMAT_MESSAGE_IGNORE_INSERTS,NULL,GetLastError(),0,(LPTSTR)&msg1,0,NULL);
	if (fm==0)
		ExitProcess(1);
	args[0]=msg;
	args[1]=msg1;
	fm=FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER|FORMAT_MESSAGE_FROM_STRING|
 FORMAT_MESSAGE_ARGUMENT_ARRAY,_T("%1: %2"),0,0,(LPTSTR)&msg2,0,(va_list*)&args[0]);
	if (fm==0)
		ExitProcess(1);
	MessageBox(NULL,msg2,_T("CapsLang - Error"),MB_OK|MB_ICONERROR);
	ExitProcess(1);
}

void CALLBACK TimerCaps(HWND hWnd,UINT uMsg,UINT_PTR idEvent,DWORD dwTime) {
	if ((GetKeyState(VK_SCROLL)>0) !=
// (GetKeyboardLayout(GetWindowThreadProcessId(GetAncestor(GetFocusWindow(), GA_PARENT),NULL))!=caps_default)) {
// (GetKeyboardLayout(GetCurrentThreadId())!=caps_default)) {
	(GetKeyboardLayout(GetWindowThreadProcessId(GetFocusWindow(), NULL))!=caps_default)) {
		ToggleLight();
	}
}

int APIENTRY WinMain(HINSTANCE hInst, HINSTANCE hInstPrev, LPSTR cmd, int show) {
	MSG		msg;

	caps_hEvent=CreateEvent(NULL,TRUE,FALSE,_T("CapsLang"));
	if (caps_hEvent==NULL)
		failed(_T("CreateEvent()"));
	if (GetLastError()==ERROR_ALREADY_EXISTS) {
		failedx(_T("CapsLang is already running!"));
		goto quit;
	}

	if (SetTimer(NULL,0,700,TimerCaps)==0)
		failed(_T("SetTimer()"));

	caps_default = GetKeyboardLayout(0);
	if (RegisterHotKey(0,EXIT,MOD_CONTROL|MOD_ALT,'L')==0)
		failed(_T("RegisterHotKey()"));

	caps_khook=SetWindowsHookEx(WH_KEYBOARD_LL,KbdHook,GetModuleHandle(0),0);
	if (caps_khook==0)
		failed(_T("SetWindowsHookEx()"));

	while (GetMessage(&msg,0,0,0)) {
		TranslateMessage(&msg);
		if(msg.message==WM_HOTKEY && msg.wParam==EXIT) PostQuitMessage(0);
		DispatchMessage(&msg);
	}

	UnhookWindowsHookEx(caps_khook);
	CloseHandle(caps_hEvent);
quit:
	ExitProcess(0);
	return 0;
}
