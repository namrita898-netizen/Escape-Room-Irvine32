# Escape Room (MASM + Irvine32)

A text-based escape room game written in x86 assembly language (MASM) using the Irvine32 library.

You are a codebreaker locked inside Blackwood Research Facility. To get out, you must solve the puzzles in 3 rooms, collect the 3 fragments of the master password, and open the Final Vault.

## How the game works

| Room | Puzzles |
|---|---|
| Room 1 - Memory Room | Remember a sequence of digits (3 levels), a number pattern, and a hidden clue to find |
| Room 2 - Cryptography Room | Decode a Caesar cipher and a word written backwards |
| Room 3 - Intelligence Room | A math puzzle, a logic (AND) puzzle and a riddle |
| Final Vault | Enter the master password made of the 3 fragments |

- Each room hides one fragment of the master password and the password for the next door.
- The numbers, words, riddle and door passwords are random, so every game is different.
- Input is not case-sensitive, so `key` and `KEY` are the same.
- In Room 1, type `LOOK` to look around or `EXAMINE <object>` to check an object.

### Lives and scoring

- You start with 3 lives. A wrong puzzle answer costs 1 life and 25 points.
- When your lives reach 0, the game is over.
- A correct answer on the first try gives 100 points. A correct answer after a mistake gives 50 points.
- A wrong door password costs 10 points but no life.
- At the end you get 100 bonus points for every life left, and a rank based on your score.

## Requirements

- Windows
- Visual Studio 2022 with the **Desktop development with C++** workload (it includes MASM)
- The **Irvine32 library**, installed in `C:\Irvine` (the folder must contain `Irvine32.inc` and `Irvine32.lib`).
  You can download it from Kip Irvine's website: https://asmirvine.com

## How to run

1. Clone the repository:
   ```
   git clone https://github.com/namrita898-netizen/Escape-Room-Irvine32.git
   ```
2. Open `EscapeRoom.sln` in Visual Studio.
3. Set the platform to **x86** (Irvine32 is a 32-bit library), and the configuration to **Debug**.
4. Press **Ctrl + F5** to build and run the game.

If the Irvine library is in a different folder, change `C:\Irvine` in the project settings:
**Project > Properties > Linker > General > Additional Library Directories** and
**Microsoft Macro Assembler > General > Include Paths**.

## Project files

| File | Contents |
|---|---|
| `main.asm` | Main program, shared data, helper procedures, random setup and intro |
| `room1.inc` | Room 1 - Memory Room |
| `room2.inc` | Room 2 - Cryptography Room |
| `room3.inc` | Room 3 - Intelligence Room |
| `vault.inc` | Final Vault and the result screen |

Only `main.asm` is assembled. It pulls in the room files with `INCLUDE`.

## Author

Nimrita Baby
