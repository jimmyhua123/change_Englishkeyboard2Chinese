; ================================================================
; AutoHotkey v1.1  –  英文亂碼 → 注音中文重輸（無判斷版）
; 熱鍵：左 Alt + F2
; ================================================================
#NoEnv
#SingleInstance Force
SendMode Input
SetBatchLines -1

IME_HKL := 0xE0080404  ; ← 換成自己看到的注音 KLID

<!F2::
    ; 1) 取得選取文字
    ClipSaved := ClipboardAll
    Clipboard := ""
    Send ^c
    ClipWait 0.5
    if ErrorLevel {
        MsgBox 48, 錯誤, 請先反白欲轉換的文字！
        Clipboard := ClipSaved
        return
    }
    txt := RegExReplace(Clipboard, "[\r\n]")

    ; 2) 若不是注音，先切注音 HKL
    origHKL := DllCall("GetKeyboardLayout", "UInt", 0, "UPtr")
    if (origHKL != IME_HKL) {
        hklNew := DllCall("LoadKeyboardLayout"
                 , "Str", Format("{:08X}", IME_HKL), "UInt", 1, "UPtr")
        if (hklNew = 0) {
            MsgBox 48, 錯誤, 載入「微軟注音」失敗！
            Clipboard := ClipSaved
            return
        }
        DllCall("ActivateKeyboardLayout", "UPtr", hklNew, "UInt", 0)
        Sleep 120
    }

    ; 3) 固定送一次 Ctrl+Space（切到中文）
    Send {Ctrl down}{Space}{Ctrl up}
    Sleep 200

    ; 4) 重新輸入並選第一候選字
	SendInput {Raw}%txt%      ; 只送原文字，Raw 保留
	SendInput {Space}         ; 另行送真正的空白鍵


    ; 5) 還原原本 HKL（如有切換才還原）
    if (origHKL != IME_HKL)
        DllCall("ActivateKeyboardLayout", "UPtr", origHKL, "UInt", 0)

    Clipboard := ClipSaved
return
