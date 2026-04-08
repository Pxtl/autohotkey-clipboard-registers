#Requires AutoHotkey v2.0

; ============================================================
;   AHKClipboardRegisters
;   Multi‑slot clipboard registers using the 1–5 keys on Windows AutoHotkey
;   Capture: Ctrl + Shift + Win + N
;   Paste:   Ctrl + Win + N
;   Notifications via TrayTip
;   Tray menu + Reload + Suspend + Exit + About
; ============================================================

global ClipboardRegisters := []
global IsDebug := false

; ---------------------------
; Notification helper
; ---------------------------
ShowNotice(title, message) {
    TrayTip title, message, 2000  ; 2 seconds
}

; ---------------------------
; Capture Clipboard Slot N
; ---------------------------
CaptureClipboard(n) {
    global ClipboardRegisters
    global IsDebug

    savedClipboard := ClipboardAll()

    A_Clipboard := ""
    Send "^c"
    if !ClipWait(1) {
        ShowNotice("AHK Clipboard Registers", "Capture failed: No content detected.")
        A_Clipboard := savedClipboard
        return
    }

    ClipboardRegisters[n] := ClipboardAll()
    A_Clipboard := savedClipboard
    ShowNotice("AHK Clipboard Registers", "Captured to register " n)

    if (IsDebug) {
        ; ---- Diagnostic Output ----
        out := "=== Capture Event ===`n"
        out .= "Captured Slot: " n "`n`n"

        ; Current clipboard text
        out .= "Current Clipboard:`n"
        curClip := ClipboardAll()
        out .= DumpClip(curClip) "`n`n"

        ; Dump all registers
        out .= "Registers:`n"
        Loop 5 {
            idx := A_Index
            out .= "  Slot " idx ": " DumpClip(ClipboardRegisters[idx]) "`n"
        }

        MsgBox(out)
    }
}

; ---------------------------
; DEBUG method
; ---------------------------
DumpClip(clipData) {
    if (clipData is Buffer) {
        size := clipData.size
        ptr := clipData.ptr
        text := StrGet(clipData)
        return "size: " size "; ptr:" ptr "; text: " text
    } else {
        return "not buffer"
    }
}

; ---------------------------
; Paste Clipboard Slot N
; ---------------------------
PasteClipboard(n) {
    global ClipboardRegisters

    if !ClipboardRegisters[n] = "" {
        ShowNotice("Clipboard Empty", "Slot " n " has no stored content.")
        return
    }

    savedClipboard := ClipboardAll()
    A_Clipboard := ClipboardRegisters[n]
    ; sleeps are needed because often it pastes the savedClipboard
    Sleep 50
    Send "^v"
    Sleep 50
    A_Clipboard := savedClipboard
}

; ---------------------------
; Hotkeys 1–5
; ---------------------------

; Capture: Ctrl + Shift + Win + N
Loop 5 {
    ClipboardRegisters.Push("")
    Hotkey "^+#" A_Index, CaptureHotkey
}

CaptureHotkey(*) {
    ; "^+#1" → slot "1"
    n := SubStr(A_ThisHotkey, 4)
    CaptureClipboard(Integer(n))
}

; Paste: Ctrl + Win + N
Loop 5 {
    Hotkey "^#" A_Index, PasteHotkey
}

PasteHotkey(*) {
    ; "^#1" → slot "1"
    n := SubStr(A_ThisHotkey, 3)
    PasteClipboard(Integer(n))
}

; ============================================================
;   Standard AHK
; ============================================================

; Tray Menu
A_TrayMenu.Delete()

A_TrayMenu.Add("About AHKClipboardRegisters", (*) => MsgBox("
(
AHKClipboardRegisters
Multi‑slot clipboard registers using the 1–5 keys
Capture: Ctrl + Shift + Win + N
Paste:   Ctrl + Win + N
)"))

A_TrayMenu.Add()

A_TrayMenu.Add("Suspend Hotkeys", (*) => Suspend(-1))
A_TrayMenu.Add("Reload Script", (*) => Reload())
A_TrayMenu.Add("Exit", (*) => ExitApp())

A_TrayMenu.Default := "About AHKClipboardRegisters"
A_TrayMenu.ClickCount := 1

A_IconTip := "AHKClipboardRegisters — Multi-Clipboard Utility"