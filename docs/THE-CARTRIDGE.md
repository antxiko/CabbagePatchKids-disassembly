# The cartridge

16,384 bytes with the standard header: `AB` at `0x4000`, `INIT` at `0x404F`,
and STATEMENT, DEVICE and TEXT at zero. The BIOS maps it into **page 1**
(0x4000-0x7FFF) and jumps to `INIT` when it has finished booting.

## The memory map

| | |
|---|---|
| 0x4000-0x7FFF | the cartridge |
| 0xE000-0xE3FF | the game's RAM, which `INIT` clears |
| 0xE400 | the stack |

Of the cartridge, **7,981 bytes are code** (4,038 instructions) and **8,403 are
data**, in 143 named ranges. Nothing is left over.

## What the VDP is told

The eight registers live at `0x44F1` and `0x44D7` copies them to `0xE038`
before sending them:

| register | value | what it means |
|---|---|---|
| R0 | 0x02 | SCREEN 2 |
| R1 | 0xE2 | 16K, screen on, interrupts on, 16×16 sprites |
| R2 | 0x0E | name table at 0x3800 |
| R3 | 0x7F | colour table at 0x0000 |
| R4 | 0x07 | pattern table at 0x2000 |
| R5 | 0x76 | sprite attributes at 0x3B00 |
| R6 | 0x03 | sprite patterns at 0x1800 |
| R7 | 0xE1 | black border |

## How the drawings are stored

Three ways, and the listing uses all three to walk the data and find where each
block ends:

**Run-length**, unpacked by `RLE_A_VRAM` (0x4D24). A count byte: zero ends the
stream, a count with bit 7 set copies that many bytes as they are, and one
without it repeats the next byte that many times. Entered at `0x4D24` the
stream carries its own two-byte VRAM address in front; entered at `0x4D28` the
address comes in DE.

**Straight copies**, `0x4502`, with HL, DE and BC.

**Mirrored copies**, `0x6DC1`: the same, but each byte goes in with its eight
bits reversed, so one drawing serves for a thing and for the same thing facing
the other way. It counts with B, and one of the calls loads `ld bc,0x0018`,
which leaves B at zero: that copy is 256 bytes, not 24.

## The font

48 glyphs of eight bytes at `0x4A37`. **The tile code is the ASCII**, so they
run from 0x30 (`0`) to 0x5F, and `0x4635` repeats them across the three thirds
of the screen so text can be written anywhere.

![The font](imagenes/fuente.png)

After the Z there are five slots that are not letters: the word `with` that the
menu needs for «1PLAYER with JOYSTICK», and the two arrows of the menu cursor.

## The lists that draw

Two formats, both of them lists of tile codes:

- `PINTA_LISTA` (0x45E7) reads a VRAM address and then tile codes until an
  0xFF; an 0xFE in the middle starts again somewhere else. It is what paints
  the labels.
- The **label engine**, `MOTOR_DE_ROTULOS` (0x59BC), takes its three arguments
  from the **six bytes that follow its own call** —a list, a set of tiles and a
  VRAM address— and returns behind them. The list is a run of counts: with bit
  7, that many cells of one single tile; without it, that many tiles copied one
  by one; 0x80 starts a new address and 0 ends.
