; =====================================================================
;  room2.inc : ROOM 2 - THE CRYPTOGRAPHY ROOM
; =====================================================================

.data

; ---------- room 2 ----------
r2Title      BYTE "########## ROOM 2 : THE CRYPTOGRAPHY ROOM ##########",0
r2PuzzleA    BYTE "PUZZLE A: Caesar cipher. Each letter was moved FORWARD by ",0
msgDot       BYTE ".",0
msgCipher    BYTE "Encrypted word: ",0
qCaesar      BYTE "Decode it (move each letter BACK by the same amount):",0
r2PuzzleB    BYTE "PUZZLE B: The machine stored a word BACKWARDS: ",0
qReverse     BYTE "What is the original word?",0
clue2a       BYTE "The cipher machine prints a message:",0
clue2b       BYTE "   >>> FRAGMENT 2 = the word you decoded in Puzzle A <<<",0
clue2c       BYTE "Engraved on the machine: door password = ",0

; ---------- word lists (InitGame picks one word from each list) ----------
cw1          BYTE "KEY",0
cw2          BYTE "LOCK",0
cw3          BYTE "CODE",0
cw4          BYTE "GATE",0
cw5          BYTE "DOOR",0
cipherList   DWORD OFFSET cw1, OFFSET cw2, OFFSET cw3, OFFSET cw4, OFFSET cw5

rw1          BYTE "ESCAPE",0
rw2          BYTE "PUZZLE",0
rw3          BYTE "SECRET",0
rw4          BYTE "MEMORY",0
rw5          BYTE "BRAINS",0
reverseList  DWORD OFFSET rw1, OFFSET rw2, OFFSET rw3, OFFSET rw4, OFFSET rw5

.code

; =====================================================================
;                  ROOM 2 : THE CRYPTOGRAPHY ROOM
; =====================================================================
Room2_Crypto PROC
    call Clrscr
    mov  eax, lightCyan
    call SetTextColor
    PrintLine r2Title
    mov  eax, white
    call SetTextColor
    call ShowStatus
    call Crlf

    ; ----- Puzzle A : Caesar cipher -----
    ; The program encrypts the random word by adding shiftAmt to every letter.
    PrintText r2PuzzleA
    PrintNum  shiftAmt
    PrintLine msgDot
    mov  esi, cipherWord        ; ESI reads the original word
    mov  edi, OFFSET cipherBuf  ; EDI writes the encrypted word
    mov  ebx, shiftAmt          ; BL = the shift (1..5)
R2_Encrypt:
    mov  al, [esi]
    cmp  al, 0                  ; end of the word?
    je   R2_EncDone
    add  al, bl                 ; move the letter forward by the shift
    cmp  al, 'Z'
    jbe  R2_Store               ; still inside A..Z
    sub  al, 26                 ; passed Z -> go back to A (wrap around)
R2_Store:
    mov  [edi], al
    inc  esi
    inc  edi
    jmp  R2_Encrypt
R2_EncDone:
    mov  BYTE PTR [edi], 0      ; end of text

    mov  edx, OFFSET msgCipher
    call WriteString
    mov  eax, lightGreen
    call SetTextColor
    mov  edx, OFFSET cipherBuf  ; shows the encrypted word, e.g. NHB
    call WriteString
    call Crlf
    mov  eax, white
    call SetTextColor
    mov  edx, OFFSET qCaesar
    mov  esi, cipherWord        ; correct answer = the original word
    call AskText

    ; ----- Puzzle B : reversed word -----
    ; Copy the random word into reverseBuf from the last letter to the first.
    INVOKE Str_length, reverseWord   ; EAX = number of letters
    mov  ecx, eax               ; loop once per letter
    mov  esi, reverseWord
    add  esi, ecx
    dec  esi                    ; ESI = last letter of the word
    mov  edi, OFFSET reverseBuf ; EDI writes the backwards word
R2_Reverse:
    mov  al, [esi]
    mov  [edi], al
    dec  esi                    ; read backwards
    inc  edi                    ; write forwards
    loop R2_Reverse
    mov  BYTE PTR [edi], 0      ; end of text

    call Crlf
    PrintText r2PuzzleB
    PrintLine reverseBuf        ; e.g. EPACSE
    mov  edx, OFFSET qReverse
    mov  esi, reverseWord       ; correct answer = the original word
    call AskText

    ; ----- Hidden clue -----
    call Crlf
    mov  eax, lightMagenta
    call SetTextColor
    PrintLine clue2a
    mov  eax, yellow
    call SetTextColor
    PrintLine clue2b            ; fragment 2 = the decoded word
    mov  eax, lightMagenta
    call SetTextColor
    PrintText clue2c
    PrintLine door3             ; door password, e.g. OPEN83
    mov  eax, white
    call SetTextColor
    ret
Room2_Crypto ENDP
