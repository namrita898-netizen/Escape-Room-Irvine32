; =====================================================================
;  THE ULTIMATE ESCAPE ROOM
;  Assembly language : MASM + Irvine32 library
; ---------------------------------------------------------------------
;  STORY : You are locked inside Blackwood Research Facility.
;          The Main Vault needs a MASTER PASSWORD made of 3 fragments.
;          One fragment is hidden in each of the 3 rooms.
;
;  ROOM 1 Memory Room       : Puzzle A (sequence memory), Puzzle B (pattern), hidden clue
;  ROOM 2 Cryptography Room : Puzzle A (Caesar cipher),   Puzzle B (reversed word), hidden clue
;  ROOM 3 Intelligence Room : Math puzzle, Logic puzzle, Riddle, hidden clue
;  FINAL VAULT              : combine the 3 fragments  ->  for example 48KEY17
;
;  RANDOMNESS : InitGame runs once at the start and picks every value
;               (fragments, puzzle numbers, words, riddle, door passwords),
;               so every new game is different.
;
;  LIVES   : 3 lives. A wrong puzzle answer = -1 life.
;  SCORING : first try +100, second try or later +50, wrong answer -25,
;            wrong door password -10, bonus +100 for every life left.
;
;  FILES : main.asm  main, shared data, helpers, InitGame, intro
;          room1.inc Room 1      room2.inc Room 2
;          room3.inc Room 3      vault.inc Final Vault + result screen
;          Only main.asm is built. It pulls in the rooms with INCLUDE.
;
;  NOTE FOR READING THE CODE:
;  Every procedure uses EAX, EDX, ECX, ESI as temporary registers.
;  Important values (lives, score ...) are kept in memory variables.
; =====================================================================
INCLUDE Irvine32.inc

; ---------------------------------------------------------------------
;  MACRO: PrintLine  - prints a text and moves to the next line
;  (only to avoid repeating the same 3 instructions again and again)
; ---------------------------------------------------------------------
PrintLine MACRO text
    mov  edx, OFFSET text
    call WriteString
    call Crlf
ENDM

; ---------------------------------------------------------------------
;  MACRO: PrintText - prints a text and stays on the same line
;  MACRO: PrintNum  - prints the number stored in a DWORD variable
; ---------------------------------------------------------------------
PrintText MACRO text
    mov  edx, OFFSET text
    call WriteString
ENDM

PrintNum MACRO var
    mov  eax, var
    call WriteDec
ENDM

; =====================================================================
;                              DATA
; =====================================================================
.data

; ---------- game variables ----------
lives        DWORD  3              ; the player starts with 3 lives
score        SDWORD 0              ; signed, because score can go below 0
tries        DWORD  0              ; wrong attempts on the current puzzle
seqLen       DWORD  4              ; length of the digit sequence (Room 1)

; ---------- buffers (memory used to store text) ----------
inputBuf     BYTE 40 DUP(0)        ; what the player types
seqBuf       BYTE 12 DUP(0)        ; the random digits of the memory game
cipherBuf    BYTE 10 DUP(0)        ; the encrypted word of the Caesar puzzle
reverseBuf   BYTE 10 DUP(0)        ; the backwards word of the reversed-word puzzle

; ---------- pointers used by the generic question procedures ----------
questionPtr  DWORD ?
answerPtr    DWORD ?
doorPtr      DWORD ?
correctNum   SDWORD ?

; ---------- room 3 results ----------
mathResult   DWORD ?
andResult    DWORD ?
fragment3    DWORD ?

; ---------- random values (picked once by InitGame at game start) ----------
fragment1    DWORD ?               ; Room 1 fragment, 10..99
patStart     DWORD ?               ; first number of the pattern, 1..5
patRatio     DWORD ?               ; each pattern number = previous x ratio, 2..3
shiftAmt     DWORD ?               ; Caesar shift, 1..5
cipherWord   DWORD ?               ; address of the Caesar word (= fragment 2)
reverseWord  DWORD ?               ; address of the reversed-word answer
mathA        DWORD ?               ; math puzzle: (A x B) - (C / D)
mathB        DWORD ?
mathC        DWORD ?               ; C = D x k, so C / D has no remainder
mathD        DWORD ?
logicX       DWORD ?               ; logic puzzle: X AND Y, both 0..15 (4 bits)
logicY       DWORD ?
riddleQ      DWORD ?               ; address of the riddle question
riddleA      DWORD ?               ; address of the riddle answer

; ---------- passwords (built at runtime) ----------
door2        BYTE 12 DUP(0)        ; password of the door to Room 2, e.g. OPEN47
door3        BYTE 12 DUP(0)        ; password of the door to Room 3
doorVault    BYTE 12 DUP(0)        ; password of the door to the Final Vault
masterPass   BYTE 24 DUP(0)        ; fragment1 + fragment2 + fragment3
doorOpen     BYTE "OPEN",0         ; first part of the door 2 and door 3 passwords
doorWordV    BYTE "VAULT",0        ; first part of the vault door password

; ---------- general messages ----------
msgLives     BYTE "Lives: ",0
msgScore     BYTE "    Score: ",0
msgAnswer    BYTE "Your answer: ",0
msgCommand   BYTE "> ",0
msgWrong     BYTE "WRONG ANSWER!  -1 life and -25 points.",0
msgPlus      BYTE "Correct!  +",0
msgPoints    BYTE " points",0
msgLocked    BYTE "The door is locked. A keypad is waiting for a password.",0
msgDoorAsk   BYTE "Enter door password: ",0
msgDoorBad   BYTE "ACCESS DENIED!  -10 points. Try again.",0
msgDoorOk    BYTE "ACCESS GRANTED. The door opens...",0
msgComma     BYTE ", ",0
msgClose     BYTE " <<<",0

; ---------- intro ----------
introTitle   BYTE "=========== THE ULTIMATE ESCAPE ROOM ===========",0
story1       BYTE "You are a codebreaker at Blackwood Research Facility.",0
story2       BYTE "Suddenly the alarm rings and ALL doors lock: LOCKDOWN!",0
story3       BYTE "The only way out is the Main Vault, locked by a MASTER PASSWORD.",0
story4       BYTE "The password is split into 3 fragments hidden in 3 rooms.",0
story5       BYTE "Solve the puzzles, find the fragments, and escape!",0
rules0       BYTE "RULES:",0
rules1       BYTE " - You have 3 lives. A wrong answer costs 1 life.",0
rules2       BYTE " - If your lives reach 0, you are trapped forever.",0
rules3       BYTE " - First try = 100 points, later tries = 50 points.",0
rules4       BYTE " - WRITE DOWN every fragment you find!",0
; ---------- game over (also used by the result screen) ----------
msgFinal     BYTE "FINAL SCORE: ",0
msgLose1     BYTE "The lights go out. The doors seal forever...",0
msgLose2     BYTE "GAME OVER - You did not escape.",0

; =====================================================================
;                       ROOMS (one file per room)
;  Each file has its own .data (messages) and .code (procedures).
; =====================================================================
INCLUDE room1.inc
INCLUDE room2.inc
INCLUDE room3.inc
INCLUDE vault.inc

; =====================================================================
;                              CODE
; =====================================================================
.code

; ---------------------------------------------------------------------
;  MAIN : the whole game flow in one place
; ---------------------------------------------------------------------
main PROC
    call Randomize              ; start the random number generator
    call InitGame               ; pick all random values for this game

    call ShowIntro             ; story + rules

    call Room1_Memory           ; Room 1
    mov  edx, OFFSET door2
    call CheckDoor              ; password door to Room 2

    call Room2_Crypto           ; Room 2
    mov  edx, OFFSET door3
    call CheckDoor              ; password door to Room 3

    call Room3_Intelligence     ; Room 3
    mov  edx, OFFSET doorVault
    call CheckDoor              ; password door to the Final Vault

    call FinalVault             ; final challenge
    call ShowResult             ; score and rank
    exit
main ENDP

; =====================================================================
;                    HELPER PROCEDURES (used everywhere)
; =====================================================================

; ---------------------------------------------------------------------
;  ReadText : reads what the player types into inputBuf and converts
;             every small letter to a CAPITAL letter, so "key" = "KEY"
; ---------------------------------------------------------------------
ReadText PROC
    mov  edx, OFFSET inputBuf   ; where to store the text
    mov  ecx, 38                ; maximum characters
    call ReadString

    mov  esi, OFFSET inputBuf   ; ESI walks through the text
RT_Loop:
    mov  al, [esi]              ; take one character
    cmp  al, 0                  ; 0 = end of text
    je   RT_Done
    cmp  al, 'a'
    jb   RT_Next                ; below 'a' -> not a small letter
    cmp  al, 'z'
    ja   RT_Next                ; above 'z' -> not a small letter
    sub  al, 32                 ; small letter -> capital letter
    mov  [esi], al
RT_Next:
    inc  esi                    ; go to the next character
    jmp  RT_Loop
RT_Done:
    ret
ReadText ENDP

; ---------------------------------------------------------------------
;  ShowStatus : prints the lives and the score
; ---------------------------------------------------------------------
ShowStatus PROC
    mov  eax, yellow
    call SetTextColor
    mov  edx, OFFSET msgLives
    call WriteString
    mov  eax, lives
    call WriteDec
    mov  edx, OFFSET msgScore
    call WriteString
    mov  eax, score
    call WriteInt               ; WriteInt shows a signed number
    call Crlf
    mov  eax, white
    call SetTextColor
    ret
ShowStatus ENDP

; ---------------------------------------------------------------------
;  AddPoints : EAX = number of points to add to the score
; ---------------------------------------------------------------------
AddPoints PROC
    add  score, eax             ; score = score + points
    push eax                    ; save the points (the next call changes EAX)
    mov  eax, lightGreen
    call SetTextColor
    mov  edx, OFFSET msgPlus
    call WriteString
    pop  eax                    ; get the points back
    call WriteDec
    mov  edx, OFFSET msgPoints
    call WriteString
    call Crlf
    mov  eax, white
    call SetTextColor
    ret
AddPoints ENDP

; ---------------------------------------------------------------------
;  GivePoints : 100 points if the answer was correct on the first try,
;               otherwise 50 points
; ---------------------------------------------------------------------
GivePoints PROC
    mov  eax, 100
    cmp  tries, 0
    je   GP_Add                 ; no wrong attempts -> 100
    mov  eax, 50                ; had wrong attempts -> 50
GP_Add:
    call AddPoints
    ret
GivePoints ENDP

; ---------------------------------------------------------------------
;  LoseLife : -1 life, -25 points. If lives become 0 -> GAME OVER
; ---------------------------------------------------------------------
LoseLife PROC
    mov  eax, lightRed
    call SetTextColor
    PrintLine msgWrong
    dec  lives                  ; lives = lives - 1
    sub  score, 25              ; score = score - 25
    call ShowStatus
    mov  eax, 1500
    call Delay                  ; wait 1.5 seconds so the player can read
    mov  eax, white
    call SetTextColor

    cmp  lives, 0
    jg   LL_Alive               ; still have lives -> continue
    call GameOver               ; no lives left -> the game ends
LL_Alive:
    ret
LoseLife ENDP

; ---------------------------------------------------------------------
;  CheckDoor : EDX = address of the correct door password.
;              Repeats until the player enters it correctly.
; ---------------------------------------------------------------------
CheckDoor PROC
    mov  doorPtr, edx           ; remember the correct password
    call Crlf
    PrintLine msgLocked
CD_Ask:
    mov  edx, OFFSET msgDoorAsk
    call WriteString
    call ReadText
    INVOKE Str_compare, ADDR inputBuf, doorPtr   ; compare the two texts
    je   CD_Open                ; equal -> correct password

    mov  eax, lightRed
    call SetTextColor
    PrintLine msgDoorBad
    mov  eax, white
    call SetTextColor
    sub  score, 10              ; small penalty (no life is lost)
    jmp  CD_Ask
CD_Open:
    mov  eax, lightGreen
    call SetTextColor
    PrintLine msgDoorOk
    mov  eax, white
    call SetTextColor
    mov  eax, 1500
    call Delay
    ret
CheckDoor ENDP

; ---------------------------------------------------------------------
;  RandBetween : EAX = lowest value, EBX = highest value
;                returns a random number from low to high in EAX
;                (changes EBX)
; ---------------------------------------------------------------------
RandBetween PROC
    sub  ebx, eax
    inc  ebx                    ; EBX = how many values are possible
    push eax                    ; save the lowest value
    mov  eax, ebx
    call RandomRange            ; EAX = random number from 0 to count-1
    pop  ebx
    add  eax, ebx               ; move it up into the range low..high
    ret
RandBetween ENDP

; ---------------------------------------------------------------------
;  AppendStr : copies the text at ESI to the address in EDI.
;              EDI ends on the closing 0, so more text can be added after.
; ---------------------------------------------------------------------
AppendStr PROC
AS_Loop:
    mov  al, [esi]
    mov  [edi], al              ; copy one character (the 0 too)
    cmp  al, 0
    je   AS_Done
    inc  esi
    inc  edi
    jmp  AS_Loop
AS_Done:
    ret
AppendStr ENDP

; ---------------------------------------------------------------------
;  AppendNum : writes the number in EAX as text at the address in EDI.
;              EDI ends on the closing 0, so more text can be added after.
; ---------------------------------------------------------------------
AppendNum PROC
    mov  ebx, 10
    mov  ecx, 0                 ; ECX counts the digits
APN_Divide:
    mov  edx, 0                 ; DIV needs EDX = 0 before dividing
    div  ebx                    ; EAX = EAX / 10, EDX = last digit
    push edx                    ; digits come out backwards, so save them
    inc  ecx
    cmp  eax, 0
    jne  APN_Divide             ; repeat until no digits are left
APN_Write:
    pop  eax                    ; take the digits back in the right order
    add  al, '0'                ; number -> character
    mov  [edi], al
    inc  edi
    loop APN_Write
    mov  BYTE PTR [edi], 0      ; end of text
    ret
AppendNum ENDP

; ---------------------------------------------------------------------
;  MakeDoor : builds a door password, e.g. OPEN47
;             EDI = where to write it, ESI = the word part
; ---------------------------------------------------------------------
MakeDoor PROC
    call AppendStr              ; copy the word
    mov  eax, 10
    mov  ebx, 99
    call RandBetween
    call AppendNum              ; add 2 random digits
    ret
MakeDoor ENDP

; ---------------------------------------------------------------------
;  Write4Bits : prints the number in EAX as 4 binary digits, e.g. 1010b
; ---------------------------------------------------------------------
Write4Bits PROC
    mov  ebx, eax
    mov  ecx, 4                 ; 4 bits to print
W4_Loop:
    mov  al, '0'
    test ebx, 1000b             ; look at bit 3
    jz   W4_Print
    mov  al, '1'
W4_Print:
    call WriteChar
    shl  ebx, 1                 ; the next bit moves into bit 3
    loop W4_Loop
    mov  al, 'b'
    call WriteChar
    ret
Write4Bits ENDP

; ---------------------------------------------------------------------
;  AskText : asks a question whose answer is a WORD
;            EDX = question text, ESI = address of the correct word
;            Repeats until correct. Each wrong answer = lose a life.
; ---------------------------------------------------------------------
AskText PROC
    mov  questionPtr, edx
    mov  answerPtr, esi
    mov  tries, 0
AT_Ask:
    call Crlf
    mov  edx, questionPtr
    call WriteString
    call Crlf
    mov  edx, OFFSET msgAnswer
    call WriteString
    call ReadText
    INVOKE Str_compare, ADDR inputBuf, answerPtr
    je   AT_Correct
    inc  tries
    call LoseLife
    jmp  AT_Ask
AT_Correct:
    call GivePoints
    ret
AskText ENDP

; ---------------------------------------------------------------------
;  GameOver : lose screen, then the program ends
; ---------------------------------------------------------------------
GameOver PROC
    call Crlf
    mov  eax, lightRed
    call SetTextColor
    PrintLine msgLose1
    PrintLine msgLose2
    mov  eax, yellow
    call SetTextColor
    mov  edx, OFFSET msgFinal
    call WriteString
    mov  eax, score
    call WriteInt
    call Crlf
    mov  eax, white
    call SetTextColor
    call WaitMsg                ; "Press any key to continue..."
    exit
GameOver ENDP

; =====================================================================
;            RANDOM SETUP : runs once, before the game starts
; =====================================================================
InitGame PROC
    ; ----- Room 1 : fragment and number pattern -----
    mov  eax, 10
    mov  ebx, 99
    call RandBetween
    mov  fragment1, eax         ; 10..99

    mov  eax, 1
    mov  ebx, 5
    call RandBetween
    mov  patStart, eax          ; 1..5
    mov  eax, 2
    mov  ebx, 3
    call RandBetween
    mov  patRatio, eax          ; 2..3

    ; ----- Room 2 : Caesar shift and words -----
    mov  eax, 1
    mov  ebx, 5
    call RandBetween
    mov  shiftAmt, eax          ; 1..5

    mov  eax, LENGTHOF cipherList
    call RandomRange            ; EAX = random position in the list
    mov  esi, cipherList[eax*4] ; each address in the list is 4 bytes
    mov  cipherWord, esi

    mov  eax, LENGTHOF reverseList
    call RandomRange
    mov  esi, reverseList[eax*4]
    mov  reverseWord, esi

    ; ----- Room 3 : math numbers -----
    ; A and B start at 3, so A x B is always bigger than C / D (max 5)
    mov  eax, 3
    mov  ebx, 9
    call RandBetween
    mov  mathA, eax             ; 3..9
    mov  eax, 3
    mov  ebx, 9
    call RandBetween
    mov  mathB, eax             ; 3..9
    mov  eax, 2
    mov  ebx, 5
    call RandBetween
    mov  mathD, eax             ; 2..5
    mov  eax, 1
    mov  ebx, 5
    call RandBetween            ; EAX = k, the result of C / D
    mul  mathD                  ; EAX = D x k
    mov  mathC, eax

    ; ----- Room 3 : logic numbers (4 bits each) -----
    mov  eax, 16
    call RandomRange
    mov  logicX, eax            ; 0..15
    mov  eax, 16
    call RandomRange
    mov  logicY, eax            ; 0..15

    ; ----- Room 3 : riddle (question and answer use the same position) -----
    mov  eax, LENGTHOF riddleQList
    call RandomRange
    mov  esi, riddleQList[eax*4]
    mov  riddleQ, esi
    mov  esi, riddleAList[eax*4]
    mov  riddleA, esi

    ; ----- door passwords : word + 2 random digits -----
    mov  edi, OFFSET door2
    mov  esi, OFFSET doorOpen
    call MakeDoor
    mov  edi, OFFSET door3
    mov  esi, OFFSET doorOpen
    call MakeDoor
    mov  edi, OFFSET doorVault
    mov  esi, OFFSET doorWordV
    call MakeDoor
    ret
InitGame ENDP

; =====================================================================
;                          INTRO / STORY
; =====================================================================
ShowIntro PROC
    call Clrscr
    mov  eax, lightCyan
    call SetTextColor
    PrintLine introTitle
    call Crlf
    mov  eax, white
    call SetTextColor
    PrintLine story1
    PrintLine story2
    PrintLine story3
    PrintLine story4
    PrintLine story5
    call Crlf
    mov  eax, yellow
    call SetTextColor
    PrintLine rules0
    mov  eax, white
    call SetTextColor
    PrintLine rules1
    PrintLine rules2
    PrintLine rules3
    PrintLine rules4
    call Crlf
    call WaitMsg
    ret
ShowIntro ENDP

; ---------------------------------------------------------------------
;  AskMathNumber : asks for a NUMBER. The room has already printed
;                  the question. EAX = the correct number
;                  (pattern, math and logic puzzles).
;                  Repeats until correct. Each wrong answer = lose a life.
; ---------------------------------------------------------------------
AskMathNumber PROC
    mov  correctNum, eax
    mov  tries, 0
AM_Ask:
    mov  edx, OFFSET msgAnswer
    call WriteString
    call ReadInt
    cmp  eax, correctNum
    je   AM_Correct
    inc  tries
    call LoseLife
    jmp  AM_Ask
AM_Correct:
    call GivePoints
    ret
AskMathNumber ENDP

END main
