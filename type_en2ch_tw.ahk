; ================================================================
; AutoHotkey v1.1 ─ 英文亂碼 → 注音輸入法中文重輸
; 熱鍵：左 Alt + F2   (<!F2)
; ================================================================
#NoEnv
#SingleInstance Force
SendMode Input
SetBatchLines -1

;------------ 常量：IME / HKL ------------------------------------
IME_HKL := 0xE01E0404  ; Microsoft Bopomofo，若用其他注音改此值

;------------ 函式：確保注音輸入法處於中文模式  ------------------
EnsureChineseMode()
{
    hWnd := WinActive("A")
    if !hWnd
        return false
    hIMC := DllCall("imm32\ImmGetContext", "Ptr", hWnd, "Ptr")
    if !hIMC
        return false

    IME_CMODE_NATIVE := 0x1        ; 中文 (Native)
    VarSetCapacity(convMode, 4, 0)
    VarSetCapacity(sentMode, 4, 0)
    if !DllCall("imm32\ImmGetConversionStatus"
        , "Ptr", hIMC
        , "UInt*", convMode
        , "UInt*", sentMode)
    {
        DllCall("imm32\ImmReleaseContext", "Ptr", hWnd, "Ptr", hIMC)
        return false
    }

    if !(convMode & IME_CMODE_NATIVE)  ; 若仍是英數模式
    {
        newConv := convMode | IME_CMODE_NATIVE
        DllCall("imm32\ImmSetConversionStatus"
            , "Ptr", hIMC
            , "UInt", newConv
            , "UInt", sentMode)
    }
    DllCall("imm32\ImmReleaseContext", "Ptr", hWnd, "Ptr", hIMC)

    ; 再次確認
    hIMC2 := DllCall("imm32\ImmGetContext", "Ptr", hWnd, "Ptr")
    ok := false
    if hIMC2
    {
        DllCall("imm32\ImmGetConversionStatus", "Ptr", hIMC2
            , "UInt*", chkConv, "UInt*", chkSent)
        ok := (chkConv & IME_CMODE_NATIVE)
        DllCall("imm32\ImmReleaseContext", "Ptr", hWnd, "Ptr", hIMC2)
    }
    return ok
}

;------------ 熱鍵：左 Alt + F2 ----------------------------------
<!F2::
    ;--- 取得並清理選取文字 ---
    ClipSaved := ClipboardAll
    Clipboard := ""
    Send ^c
    ClipWait, 0.5
    if ErrorLevel
    {
        MsgBox, 48, 錯誤, 請先反白欲轉換的文字！
        Clipboard := ClipSaved
        return
    }
    rawText := Clipboard
    StringReplace, rawText, rawText, `r,, All
    StringReplace, rawText, rawText, `n,, All

    ;--- 切換到注音輸入法 ---
    origLayout := DllCall("GetKeyboardLayout", "UInt", 0, "UPtr")
    hklNew     := DllCall("LoadKeyboardLayout", "Str", Format("{:08X}", IME_HKL)
                    , "UInt", 1, "UPtr")
    DllCall("ActivateKeyboardLayout", "UPtr", hklNew, "UInt", 0)
    Sleep, 120

    ;--- 確保中文模式，失敗則用 Ctrl+Space 嘗試 ---
    if !EnsureChineseMode()
    {
        Loop, 3
        {
            Send {Ctrl down}{Space}{Ctrl up}
            Sleep, 80
            if EnsureChineseMode()
                break
        }
    }

    ;--- 重新輸入並上屏 ---
    SendInput {Raw}%rawText%
    SendInput {Space}      ; 上第一候選字

    ;--- 還原原鍵盤配置 & 剪貼簿 ---
    DllCall("ActivateKeyboardLayout", "UPtr", origLayout, "UInt", 0)
    Clipboard := ClipSaved
return
