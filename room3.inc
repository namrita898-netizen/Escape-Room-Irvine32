; =====================================================================
;  room3.inc : ROOM 3 - THE INTELLIGENCE ROOM
; =====================================================================

.data

; ---------- room 3 ----------
r3Title      BYTE "########## ROOM 3 : THE INTELLIGENCE ROOM ##########",0
r3Math       BYTE "PUZZLE A (Math):   (",0
msgTimes     BYTE " x ",0
msgMinus     BYTE ") - (",0
msgDivide    BYTE " / ",0
r3MathEnd    BYTE ") = ?",0
r3Logic      BYTE "PUZZLE B (Logic):  ",0
msgAnd       BYTE " AND ",0
r3LogicEnd   BYTE " = ?   (answer in decimal)",0
r3Riddle     BYTE "PUZZLE C (Riddle)",0
clue3a       BYTE "The computer calculates: Fragment 3 = Math answer + Logic answer",0
clue3b       BYTE "   >>> FRAGMENT 3 = ",0
clue3d       BYTE "On the screen: door password = ",0

; ---------- riddle list (InitGame picks one riddle) ----------
rq1          BYTE "I have keys but open no locks. What am I?",0
rq2          BYTE "What has hands but cannot clap?",0
rq3          BYTE "What gets wetter the more it dries?",0
ra1          BYTE "KEYBOARD",0
ra2          BYTE "CLOCK",0
ra3          BYTE "TOWEL",0
riddleQList  DWORD OFFSET rq1, OFFSET rq2, OFFSET rq3
riddleAList  DWORD OFFSET ra1, OFFSET ra2, OFFSET ra3   ; same order as the questions

.code

; =====================================================================
;                 ROOM 3 : THE INTELLIGENCE ROOM
; =====================================================================
Room3_Intelligence PROC
    call Clrscr
    mov  eax, lightCyan
    call SetTextColor
    PrintLine r3Title
    mov  eax, white
    call SetTextColor
    call ShowStatus
    call Crlf

    ; ----- Puzzle A : math  (A x B) - (C / D) -----
    PrintText r3Math
    PrintNum  mathA
    PrintText msgTimes
    PrintNum  mathB
    PrintText msgMinus
    PrintNum  mathC
    PrintText msgDivide
    PrintNum  mathD
    PrintLine r3MathEnd
    mov  eax, mathA
    mov  ebx, mathB
    mul  ebx                    ; EAX = A x B
    mov  ecx, eax               ; keep A x B in ECX
    mov  eax, mathC
    mov  edx, 0                 ; DIV needs EDX = 0 before dividing
    mov  ebx, mathD
    div  ebx                    ; EAX = C / D
    sub  ecx, eax               ; ECX = (A x B) - (C / D)
    mov  eax, ecx
    mov  mathResult, eax        ; save it for fragment 3
    call AskMathNumber          ; EAX = the correct answer

    ; ----- Puzzle B : logic  X AND Y -----
    call Crlf
    PrintText r3Logic
    mov  eax, logicX
    call Write4Bits
    PrintText msgAnd
    mov  eax, logicY
    call Write4Bits
    PrintLine r3LogicEnd
    mov  eax, logicX
    and  eax, logicY            ; AND keeps a bit only if both are 1
    mov  andResult, eax         ; save it for fragment 3
    call AskMathNumber

    ; ----- Puzzle C : riddle -----
    call Crlf
    PrintLine r3Riddle
    mov  edx, riddleQ           ; random riddle question
    mov  esi, riddleA           ; its matching answer
    call AskText

    ; ----- Hidden clue : Fragment 3 = math answer + logic answer -----
    call Crlf
    mov  eax, lightMagenta
    call SetTextColor
    PrintLine clue3a
    mov  eax, mathResult
    add  eax, andResult
    mov  fragment3, eax
    mov  eax, yellow
    call SetTextColor
    PrintText clue3b
    PrintNum  fragment3
    PrintLine msgClose
    mov  eax, lightMagenta
    call SetTextColor
    PrintText clue3d
    PrintLine doorVault         ; door password, e.g. VAULT25
    mov  eax, white
    call SetTextColor
    ret
Room3_Intelligence ENDP
