SetTitleMatchMode 2
#WinActivateForce
#singleinstance force

#persistent
RegRead, SPATH, HKEY_CLASSES_ROOT, spotify\DefaultIcon,
StringGetPos, POS, SPATH, \spotify.exe
StringReplace, SPATH, SPATH, `,0 ,,A
StringReplace, SPATH, SPATH, ",,A

Run, %SPATH%



SetTimer, RefreshTrayTip, 1000
playingsave := ""
Gosub, RefreshTrayTip  ; Call it once to get it started right away.


SetTimer, RefreshTrayTip2, 1000
Gosub, RefreshTrayTip2  ; Call it once to get it started right away.


SetTimer, SpotifyExit, 5000
Gosub, SpotifyExit  ; Call it once to get it started right away.




Menu, Tray, NoStandard
Menu, tray, add, Show/Hide Spotify, spotify
Menu, tray, add
Menu, tray, add, Play/Pause, Playp  ; Creates a new menu item.
Menu, Tray, add, Next, l_defaultaction
Menu, Tray, Default, Next
Menu, Tray, Click, 1
Menu, tray, add, Previous, prev
Menu, tray, add
Menu, tray, add, Exit, Ex




{DetectHiddenWindows, Off
   Sleep, 1050
 WinWaitClose, Spotify, , 15
 DetectHiddenWindows, On
RegExMatch(TrayIcons("spotify.exe"), "(?<=idn: )\d+", idn) ; This finds out the ID of the Tray Icon of "yourapp.exe"
HideTrayIcon(idn) ; This hides that icon :D
}
return



l_defaultaction:
if tray_clicks > 0 ; SetTimer already started, so we log the keypress instead.
{
   tray_clicks += 1
   return
}
; Otherwise, this is the first press of a new series. Set count to 1 and start
; the timer:
tray_clicks = 1
SetTimer, tray_clicks_check, 400 ; Wait for more presses within a 400 millisecond window.
return

tray_clicks_check:
SetTimer, tray_clicks_check, off
if tray_clicks = 1 ; The key was pressed once.
{
DetectHiddenWindows, On
ControlSend, ahk_parent, ^{Right}, ahk_class SpotifyMainWindow
DetectHiddenWindows, Off
}
else if tray_clicks = 2 ; The key was pressed twice.
{
WinShow, ahk_Class SpotifyMainWindow
WinActivate, ahk_Class SpotifyMainWindow
}
else if tray_clicks > 2
{
DetectHiddenWindows, On
ControlSend, ahk_parent, ^{Left}, ahk_class SpotifyMainWindow
DetectHiddenWindows, Off
}
; Regardless of which action above was triggered, reset the count to
; prepare for the next series of presses:
tray_clicks = 0
return


; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




/*
WM_MOUSEMOVE	= 0x0200
WM_LBUTTONDOWN	= 0x0201
WM_LBUTTONUP	= 0x0202
WM_LBUTTONDBLCLK= 0x0203
WM_RBUTTONDOWN	= 0x0204
WM_RBUTTONUP	= 0x0205
WM_RBUTTONDBLCLK= 0x0206
WM_MBUTTONDOWN	= 0x0207
WM_MBUTTONUP	= 0x0208
WM_MBUTTONDBLCLK= 0x0209

PostMessage, nMsg, uID, WM_RBUTTONDOWN, , ahk_id %hWnd%
PostMessage, nMsg, uID, WM_RBUTTONUP  , , ahk_id %hWnd%
*/















TrayIcons(sExeName = "spotify.exe")
{
	WinGet,	pidTaskbar, PID, ahk_class Shell_TrayWnd
	hProc:=	DllCall("OpenProcess", "Uint", 0x38, "int", 0, "Uint", pidTaskbar)
	pProc:=	DllCall("VirtualAllocEx", "Uint", hProc, "Uint", 0, "Uint", 32, "Uint", 0x1000, "Uint", 0x4)
	idxTB:=	GetTrayBar()
		SendMessage, 0x418, 0, 0, ToolbarWindow32%idxTB%, ahk_class Shell_TrayWnd   ; TB_BUTTONCOUNT
	Loop,	%ErrorLevel%
	{
		SendMessage, 0x417, A_Index-1, pProc, ToolbarWindow32%idxTB%, ahk_class Shell_TrayWnd   ; TB_GETBUTTON
		VarSetCapacity(btn,32,0), VarSetCapacity(nfo,32,0)
		DllCall("ReadProcessMemory", "Uint", hProc, "Uint", pProc, "Uint", &btn, "Uint", 32, "Uint", 0)
			iBitmap	:= NumGet(btn, 0)
			idn	:= NumGet(btn, 4)
			Statyle := NumGet(btn, 8)
		If	dwData	:= NumGet(btn,12)
			iString	:= NumGet(btn,16)
		Else	dwData	:= NumGet(btn,16,"int64"), iString:=NumGet(btn,24,"int64")
		DllCall("ReadProcessMemory", "Uint", hProc, "Uint", dwData, "Uint", &nfo, "Uint", 32, "Uint", 0)
		If	NumGet(btn,12)
			hWnd	:= NumGet(nfo, 0)
		,	uID	:= NumGet(nfo, 4)
		,	nMsg	:= NumGet(nfo, 8)
		,	hIcon	:= NumGet(nfo,20)
		Else	hWnd	:= NumGet(nfo, 0,"int64"), uID:=NumGet(nfo, 8), nMsg:=NumGet(nfo,12)
		WinGet, pid, PID,              ahk_id %hWnd%
		WinGet, sProcess, ProcessName, ahk_id %hWnd%
		WinGetClass, sClass,           ahk_id %hWnd%
		If !sExeName || (sExeName = sProcess) || (sExeName = pid)
			VarSetCapacity(sTooltip,128), VarSetCapacity(wTooltip,128*2)
		,	DllCall("ReadProcessMemory", "Uint", hProc, "Uint", iString, "Uint", &wTooltip, "Uint", 128*2, "Uint", 0)
		,	DllCall("WideCharToMultiByte", "Uint", 0, "Uint", 0, "str", wTooltip, "int", -1, "str", sTooltip, "int", 128, "Uint", 0, "Uint", 0)
		,	sTrayIcons .= "idx: " . A_Index-1 . " | idn: " . idn . " | Pid: " . pid . " | uID: " . uID . " | MessageID: " . nMsg . " | hWnd: " . hWnd . " | Class: " . sClass . " | Process: " . sProcess . "`n" . "   | Tooltip: " . sTooltip . "`n"
	}
	DllCall("VirtualFreeEx", "Uint", hProc, "Uint", pProc, "Uint", 0, "Uint", 0x8000)
	DllCall("CloseHandle", "Uint", hProc)
	Return	sTrayIcons
}

RemoveTrayIcon(hWnd, uID, nMsg = 0, hIcon = 0, nRemove = 2)
{
	NumPut(VarSetCapacity(ni,444,0), ni)
	NumPut(hWnd , ni, 4)
	NumPut(uID  , ni, 8)
	NumPut(1|2|4, ni,12)
	NumPut(nMsg , ni,16)
	NumPut(hIcon, ni,20)
	Return	DllCall("shell32\Shell_NotifyIconA", "Uint", nRemove, "Uint", &ni)
}

HideTrayIcon(idn, bHide = True)
{
	idxTB := GetTrayBar()
	SendMessage, 0x404, idn, bHide, ToolbarWindow32%idxTB%, ahk_class Shell_TrayWnd   ; TB_HIDEBUTTON
	SendMessage, 0x1A, 0, 0, , ahk_class Shell_TrayWnd
}

DeleteTrayIcon(idx)
{
	idxTB := GetTrayBar()
	SendMessage, 0x416, idx - 1, 0, ToolbarWindow32%idxTB%, ahk_class Shell_TrayWnd   ; TB_DELETEBUTTON
	SendMessage, 0x1A, 0, 0, , ahk_class Shell_TrayWnd
}

MoveTrayIcon(idxOld, idxNew)
{
	idxTB := GetTrayBar()
	SendMessage, 0x452, idxOld - 1, idxNew - 1, ToolbarWindow32%idxTB%, ahk_class Shell_TrayWnd ; TB_MOVEBUTTON
}

GetTrayBar()
{
	ControlGet, hParent, hWnd,, TrayNotifyWnd1  , ahk_class Shell_TrayWnd
	ControlGet, hChild , hWnd,, ToolbarWindow321, ahk_id %hParent%
	Loop
	{
		ControlGet, hWnd, hWnd,, ToolbarWindow32%A_Index%, ahk_class Shell_TrayWnd
		If  Not	hWnd
			Break
		Else If	hWnd = %hChild%
		{
			idxTB := A_Index
			Break
		}
	}
	Return	idxTB
}

Return









; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;





; "CTRL + Alt + S"  for shuffle toggle
^!s::
{
DetectHiddenWindows, On
ControlSend, ahk_parent, ^s, ahk_class SpotifyMainWindow
DetectHiddenWindows, Off
return
}


; "CTRL + PAGE UP"  for volume up
^PgUP::
{
DetectHiddenWindows, On
ControlSend, ahk_parent, ^{Up}, ahk_class SpotifyMainWindow
DetectHiddenWindows, Off
return
}

; "CTRL + PAGE DOWN"  for volume down
^PgDn::
{
DetectHiddenWindows, On
ControlSend, ahk_parent, ^{Down}, ahk_class SpotifyMainWindow
DetectHiddenWindows, Off
return
}

; "CTRL + Left"  for previous
^Left::
DetectHiddenWindows, On
ControlSend, ahk_parent, ^{Left}, ahk_class SpotifyMainWindow
DetectHiddenWindows, Off
return


; "CTRL + Right"  for next
^Right::
{
DetectHiddenWindows, On
ControlSend, ahk_parent, ^{Right}, ahk_class SpotifyMainWindow
DetectHiddenWindows, Off
return
}

; "CTRL + Alt + Left"  for seeking backward
^!LEFT::
{
DetectHiddenWindows, On
ControlSend, ahk_parent, +{Left}, ahk_class SpotifyMainWindow
DetectHiddenWindows, Off
return
}

; "CTRL + Alt + Right"  for seeking forward
^!RIGHT::
{
DetectHiddenWindows, On
ControlSend, ahk_parent, +{Right}, ahk_class SpotifyMainWindow
DetectHiddenWindows, Off
return
}

; "CTRL + Down"  for info
^Down::
{
DetectHiddenWindows, On
SetTitleMatchMode 2
WinGetTitle, now_playing, ahk_class SpotifyMainWindow
StringTrimLeft, playing, now_playing, 10
TrayTip, Now playing:, %playing%., 10 , 16
DetectHiddenWindows, Off
return
}

; "CTRL + UP"  for pause
^UP::
{
DetectHiddenWindows, On
ControlSend, ahk_parent, {space}, ahk_class SpotifyMainWindow
DetectHiddenWindows, Off
return
}

; "CTRL + ALT + DOWN"  To show/hide spotify window
^!DOWN::
{
DetectHiddenWindows, On
ifWinNotActive, ahk_Class SpotifyMainWindow
{
WinShow, ahk_Class SpotifyMainWindow
WinActivate, ahk_Class SpotifyMainWindow
}
else ifWinActive, ahk_Class SpotifyMainWindow
WinClose, ahk_Class SpotifyMainWindow
DetectHiddenWindows, Off
return
}


; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


RefreshTrayTip:
DetectHiddenWindows, On
WinGetTitle, now_playing, ahk_class SpotifyMainWindow
StringTrimLeft, playing, now_playing, 10
if(playing != playingsave) {
  TrayTip, Now playing:, %playing%, 10 , 16
  SetTimer, RemoveTrayTip, -5000
}
playingsave := playing
return

RemoveTrayTip:
    TrayTip
    return

RefreshTrayTip2:
WinGetTitle, title, ahk_class SpotifyMainWindow
Menu, Tray, Tip, %title%
return




Playp:
{
DetectHiddenWindows, On
ControlSend, ahk_parent, {space}, ahk_class SpotifyMainWindow
DetectHiddenWindows, Off
return
}


Ex:
ExitApp
return


next:
{
DetectHiddenWindows, On
ControlSend, ahk_parent, ^{Right}, ahk_class SpotifyMainWindow
DetectHiddenWindows, Off
return
}

prev:
DetectHiddenWindows, On
ControlSend, ahk_parent, ^{Left}, ahk_class SpotifyMainWindow
DetectHiddenWindows, Off
return


spotify:
{
DetectHiddenWindows, Off
ifWinNotExist, ahk_Class SpotifyMainWindow
{
WinShow, ahk_Class SpotifyMainWindow
}
else ifWinExist, ahk_Class SpotifyMainWindow
WinClose, ahk_Class SpotifyMainWindow
return
}

SpotifyExit:
 Sleep, 2000
DetectHiddenWindows, On
IfWinNotExist, ahk_class SpotifyMainWindow
ExitApp
Return