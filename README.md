# Cabbage Patch Kids (Konami, RC-716) — commented disassembly

A commented disassembly of the 16 KB MSX cartridge, reproducible byte for byte.

**[Read the write-up →](https://antxiko.github.io/CabbagePatchKids-disassembly/)**
· [En castellano](README.es.md)

    make            # trace, generate the listing, reassemble it and run the tests
    make verify     # the test that decides: reassembling has to give the ROM back
    make sanity     # that not one byte is left unexplained
    make densidad   # how much is commented, routine by routine
    make imagenes   # redraws the pictures from the ROM
    make web        # rebuild the website

The ROM is **not distributed here**. It goes in the root as `cabbagepatch.rom`,
16384 bytes, sha256

    114945c770531db3ae61eb330d7ed870a3c00d3a90db2a29a4c134135c2c0707

`make comprueba` checks it.

## Where it stands

| | |
|---|---|
| reassembles byte for byte | yes |
| bytes explained | 16,384 of 16,384 (100 %) |
| traced code | 7,981 bytes, 4,038 instructions |
| identified data | 8,403 bytes in 143 named ranges |
| commented | 988 line comments, 24.5 % |
| thin routines (under 10 %) | 0 of 562 |

The annotations live apart from the listing, anchored to the address they
describe, so they survive a re-trace. What the `.notes` file holds:

| | |
|---|---|
| named labels | 314 |
| anchored comments | 974 |
| explained data ranges | 143 |

## A few things that turned up

- **Before you play, the cartridge asks you two things**: which kid you want,
  and what it is called. The name is ten letters that come out of the factory
  saying **ANNA LEE**, written into the player's start-up values right next to
  the three lives and the clock — and it stays on screen for the whole game.
- **The park is called BABYLAND PARK**, and the babies grow in cabbages.
- **439 bytes of another cartridge's scenery ride along, unused.** Three blocks
  are byte-for-byte data from Konami's earlier MSX game, moved here by a fixed
  offset, and nothing in this binary points at them. This game is that engine
  recompiled: 68.5 % of its instructions line up one to one.
- **The whole game runs inside the interrupt.** `INIT` hooks it and drops into
  a two-byte loop for ever; a latch makes the game slow down rather than trip
  over itself when a frame runs long.
- **The dispatcher finds its own table**: it `pop`s the return address, which is
  where the table of words starts, and never comes back to the `call`. What has
  to run *after* a state is pushed on the stack beforehand — and without seeing
  that, 138 bytes of code look like data.
- **One instruction is written into RAM**, because the Z80 does not have it: a
  seven-byte routine that self-modifies its own displacement to do
  `ld (IX+A),B`.
- **It does not carry Konami's hidden mark.** The format was found by Manuel
  Pazos; this cartridge has no `0xAA` closing anything at the end of the ROM.

## What is in here

- `src/cabbagepatch.asm` — the listing; generated, not hand-edited
- `src/cabbagepatch.notes` — the annotations, anchored to addresses
- `src/cabbagepatch.entries` — the entry points, each one justified
- `src/cabbagepatch.nocode` — the dispatch tables the tracer must not walk into
- `docs/` — the website, in English and Spanish
- `tools/` — the tracer, the listing generator, the format walkers, the drawing
  tools, and `repasa_el_porte.py`, the guardian for the ported annotations

## The write-up

| | |
|---|---|
| [Getting started](docs/GETTING-STARTED.md) | what you need and what each command does |
| [The game](docs/THE-GAME.md) | Babyland Park, and the two questions before you play |
| [The cartridge](docs/THE-CARTRIDGE.md) | the header, the memory map and how the drawings are stored |
| [The code](docs/THE-CODE.md) | the interrupt, the dispatcher and the sound |
| [Findings](docs/FINDINGS.md) | what the binary says |
| [In the emulator](docs/IN-THE-EMULATOR.md) | what was checked by running it |
| [Open questions](docs/OPEN-QUESTIONS.md) | what is still not settled |

See `LEGAL-NOTICE.md`.
