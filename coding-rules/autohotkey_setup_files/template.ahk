; ============================================================================
;  TEMPLATE — copy this file, rename it, and replace the GUID + class name.
;  A persistent toggle script: first run starts it, second run exits it.
; ============================================================================

#NoEnv                       ; recommended for performance and compatibility
SendMode Input               ; faster, more reliable Send
#SingleInstance off          ; toggle is handled by SingleInstance.ahk, not AHK
#Persistent                  ; keep running after the auto-execute section
SetWorkingDir %A_ScriptDir%

#Include %A_ScriptDir%\_libraries\SingleInstance.ahk

; --- Single-instance toggle -------------------------------------------------
; The class is the script's lifecycle. __New() runs on first launch, Quit() runs
; when a SECOND launch finds this instance already active (both then exit).
class MyScriptObject {
    __New() {
        ; one-time startup work goes here
        ; MsgBox Starting MyScript
    }
    IsActive() {
        return true
    }
    Quit() {
        ; shutdown / cleanup work goes here
        ; MsgBox Shutting down MyScript
        ExitApp
    }
}

; Generate a fresh, unique GUID per script (do NOT reuse another script's GUID).
CheckSingleInstance("{REPLACE-WITH-A-UNIQUE-GUID}", "MyScriptObject")

; --- Tray menu --------------------------------------------------------------
Menu, tray, NoStandard
Menu, tray, add                 ; separator
Menu, tray, add, Reload, TrayReload
Menu, tray, add, Exit, TrayExit

; --- Clean exit: free the single-instance COM slot before quitting ----------
OnExit("Revoke")

; ============================================================================
;  Hotkeys / logic below
; ============================================================================

; #+a::                         ; example: Win+Shift+A
;     ; do work
; return

; --- Handlers ---------------------------------------------------------------
TrayReload:
    Reload
return

TrayExit:
    ExitApp
return

Revoke(ExitReason, ExitCode) {
    global ActiveObject
    ObjRegisterActive(ActiveObject, "")   ; unregister so a relaunch starts fresh
}
