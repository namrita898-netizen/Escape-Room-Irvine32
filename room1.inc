; =====================================================================
;  room1.inc : ROOM 1 - THE MEMORY ROOM
; =====================================================================

.data

; ---------- room 1 ----------
r1Title      BYTE "########## ROOM 1 : THE MEMORY ROOM ##########",0
r1Info       BYTE "PUZZLE A: Digits will flash for 3 seconds. Remember them!",0
msgMemorize  BYTE "Memorize these digits: ",0
msgRetype    BYTE "Type the digits you saw: ",0
r1PuzzleB    BYTE "PUZZLE B: Number pattern",0
qPattern     BYTE "?   What is the next number?",0
r1Explore    BYTE "Solved! A clue is hidden here. Type LOOK or EXAMINE <object>.",0
msgLook      BYTE "You see a desk, a dead monitor and a crooked PAINTING.",0
msgNothing   BYTE "Nothing happens.",0
clue1a       BYTE "Behind the painting you find a note:",0
clue1b       BYTE "   >>> FRAGMENT 1 = ",0
clue1c       BYTE "Scratched on the frame: door password = ",0

; ---------- commands the player can type ----------
cmdLook      BYTE "LOOK",0
cmdPainting  BYTE "EXAMINE PAINTING",0

.code

; =====================================================================
;                    ROOM 1 : THE MEMORY ROOM
; =====================================================================
Room1_Memory PROC
    call Clrscr
    mov  eax, lightCyan
    call SetTextColor
    PrintLine r1Title
    mov  eax, white
    call SetTextColor
    call ShowStatus
    call Crlf
    PrintLine r1Info
    call WaitMsg

    ; ----- Puzzle A : memory sequence game -----
    call SequenceGame

    ; ----- Puzzle B : number pattern (each number = previous x ratio) -----
    call Clrscr
    PrintLine r1PuzzleB
    mov  eax, patStart          ; first number of the pattern
    mov  ecx, 4                 ; show 4 numbers
R1_Pattern:
    call WriteDec
    mov  edx, OFFSET msgComma
    call WriteString
    mul  patRatio               ; next number = number x ratio
    loop R1_Pattern
    ; after the loop EAX holds the 5th number = the correct answer
    push eax                    ; save the answer while the question prints
    PrintLine qPattern
    pop  eax
    call AskMathNumber

    ; ----- Hidden clue -----
    call FindClue1
    ret
Room1_Memory ENDP

; ---------------------------------------------------------------------
;  SequenceGame : 3 levels, the sequence has 4, then 5, then 6 digits
; ---------------------------------------------------------------------
SequenceGame PROC
    mov  seqLen, 4              ; start with 4 digits
SG_Level:
    ; --- create seqLen random digits ---
    mov  ecx, seqLen            ; loop counter = number of digits
    mov  esi, OFFSET seqBuf     ; ESI = where to store the digits
SG_Make:
    mov  eax, 10
    call RandomRange            ; EAX = random number from 0 to 9
    add  al, '0'                ; number -> character ('0'..'9')
    mov  [esi], al
    inc  esi
    loop SG_Make
    mov  BYTE PTR [esi], 0      ; end of text

    ; --- show the digits for 3 seconds, then hide them ---
    call Clrscr
    mov  edx, OFFSET msgMemorize
    call WriteString
    mov  eax, yellow
    call SetTextColor
    mov  edx, OFFSET seqBuf
    call WriteString
    call Crlf
    mov  eax, 3000
    call Delay                  ; wait 3000 milliseconds
    call Clrscr                 ; clear the screen so they are hidden
    mov  eax, white
    call SetTextColor

    ; --- ask the player to type them ---
    mov  edx, OFFSET msgRetype
    call WriteString
    call ReadText
    INVOKE Str_compare, ADDR inputBuf, ADDR seqBuf
    jne  SG_Wrong               ; not equal -> wrong

    mov  eax, 50
    call AddPoints              ; +50 for each level
    mov  eax, 1000
    call Delay
    inc  seqLen                 ; next level has one more digit
    cmp  seqLen, 6
    jbe  SG_Level               ; levels with 4, 5 and 6 digits
    ret

SG_Wrong:
    call LoseLife               ; lose a life and try the level again
    jmp  SG_Level
SequenceGame ENDP

; ---------------------------------------------------------------------
;  FindClue1 : the player explores the room until he finds the painting
; ---------------------------------------------------------------------
FindClue1 PROC
    call Crlf
    mov  eax, yellow
    call SetTextColor
    PrintLine r1Explore
    mov  eax, white
    call SetTextColor
FC1_Loop:
    mov  edx, OFFSET msgCommand
    call WriteString
    call ReadText
    INVOKE Str_compare, ADDR inputBuf, ADDR cmdPainting
    je   FC1_Found
    INVOKE Str_compare, ADDR inputBuf, ADDR cmdLook
    je   FC1_Look
    PrintLine msgNothing        ; any other command
    jmp  FC1_Loop
FC1_Look:
    PrintLine msgLook
    jmp  FC1_Loop
FC1_Found:
    mov  eax, lightMagenta
    call SetTextColor
    PrintLine clue1a
    mov  eax, yellow
    call SetTextColor
    PrintText clue1b
    PrintNum  fragment1         ; FRAGMENT 1 = random 10..99
    PrintLine msgClose
    mov  eax, lightMagenta
    call SetTextColor
    PrintText clue1c
    PrintLine door2             ; door password, e.g. OPEN47
    mov  eax, white
    call SetTextColor
    ret
FindClue1 ENDP
