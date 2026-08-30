# Getting started

A commented disassembly of **Cabbage Patch Kids** (Konami, RC-716, 1984), the
16 KB MSX cartridge. Everything here comes out of the binary and can be
generated from it again.

## What you need

- **Python 3** (no third-party packages)
- **pasmo**, to reassemble
- **z80dasm**, used only for the mnemonics
- the cartridge, which this repository **does not distribute**

It goes in the root as `cabbagepatch.rom`, 16,384 bytes, sha256

    114945c770531db3ae61eb330d7ed870a3c00d3a90db2a29a4c134135c2c0707

and `make comprueba` checks it.

## The test that decides

    make verify

This reassembles `src/cabbagepatch.asm` with pasmo and compares the result,
byte for byte, with the cartridge. If it says `OK: reproducible byte a byte`,
the listing has invented nothing.

## What reassembly cannot catch

A listing can reassemble perfectly and still be wrong: if drawings are read as
instructions the bytes do not change, only what is said about them. So three
more checks run alongside, all in `make sanity`:

- **no range declared as data may come out as code** (`check_trace.py` and
  `check_datos_como_codigo.py`, which crosses all 143 declared ranges against
  the trace);
- **no entry point may fall inside one** (`check_entradas.py`) — if both are
  declared at once, one of them is false;
- **not one byte left unassigned** (`presupuesto.py`). Today it says
  **16,384 of 16,384, 100%**.

## Everything you can run

    make            # trace, listing, verify and the tests
    make listado    # regenerates src/cabbagepatch.asm from the annotations
    make sanity     # the checks reassembly does not cover
    make densidad   # how much is commented, routine by routine
    make imagenes   # redraws the PNGs in docs/imagenes from the ROM
    make web        # regenerates this site
    make test       # the tests

And one more that is specific to this cartridge:

    python3 tools/repasa_el_porte.py

The annotations were **ported from another cartridge** — see
[Findings](FINDINGS.md) — and that tool is the guardian for it: it checks that
no address cited in a comment is a leftover, that the other game is not named
where it should not be, and it lists every comment that is identical to the
sibling's but sits on a different instruction.

## What is in here

- `src/cabbagepatch.asm` — the listing; generated, not hand-edited
- `src/cabbagepatch.notes` — the annotations, anchored to addresses
- `src/cabbagepatch.entries` — the entry points, each one justified
- `src/cabbagepatch.nocode` — the dispatch tables, which the tracer must not
  read as code
- `docs/` — this site, in English and Spanish
- `tools/` — the tracer, the listing generator, the format walkers and the
  drawing tools
