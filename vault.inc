; =====================================================================
;  vault.inc : THE FINAL VAULT and the RESULT SCREEN
; =====================================================================

.data

; ---------- final vault ----------
r4Title      BYTE "########## THE FINAL VAULT ##########",0
r4Info       BYTE "Combine fragment 1 + 2 + 3 in order, with no spaces.",0
qVault       BYTE "Enter the MASTER PASSWORD:",0

; ---------- win screen ----------
msgWin       BYTE "*** THE VAULT OPENS! YOU ESCAPED! ***",0
msgBonus     BYTE "Bonus for lives left: +",0
msgRank      BYTE "YOUR RANK: ",0
rankHigh     BYTE "MASTER ESCAPIST",0
rankMid      BYTE "CODEBREAKER",0
rankLow      BYTE "LUCKY SURVIVOR",0

.code

; =====================================================================
;                          THE FINAL VAULT
; =====================================================================
FinalVault PROC
    call Clrscr
    mov  eax, lightCyan
    call SetTextColor
    PrintLine r4Title
    mov  eax, white
    call SetTextColor
    PrintLine r4Info
    call ShowStatus

    ; ----- build the master password: fragment1 + word + fragment3 -----
    mov  edi, OFFSET masterPass
    mov  eax, fragment1
    call AppendNum              ; e.g. "48"
    mov  esi, cipherWord
    call AppendStr              ; e.g. "48KEY"
    mov  eax, fragment3
    call AppendNum              ; e.g. "48KEY17"

    mov  edx, OFFSET qVault
    mov  esi, OFFSET masterPass ; correct answer = the 3 fragments together
    call AskText

    mov  eax, 100               ; extra reward for opening the vault
    call AddPoints
    ret
FinalVault ENDP

; =====================================================================
;                          RESULT SCREEN
; =====================================================================
ShowResult PROC
    call Crlf
    mov  eax, lightGreen
    call SetTextColor
    PrintLine msgWin

    mov  eax, yellow
    call SetTextColor
    mov  edx, OFFSET msgBonus
    call WriteString
    mov  eax, lives
    imul eax, 100               ; +100 points for every life left
    add  score, eax
    call WriteDec
    call Crlf

    mov  edx, OFFSET msgFinal
    call WriteString
    mov  eax, score
    call WriteInt
    call Crlf

    mov  edx, OFFSET msgRank
    call WriteString
    cmp  score, 1000
    jge  SR_High
    cmp  score, 700
    jge  SR_Mid
    PrintLine rankLow           ; below 700
    jmp  SR_End
SR_High:
    PrintLine rankHigh          ; 1000 or more
    jmp  SR_End
SR_Mid:
    PrintLine rankMid           ; 700 to 999
SR_End:
    mov  eax, white
    call SetTextColor
    call Crlf
    call WaitMsg
    ret
ShowResult ENDP
