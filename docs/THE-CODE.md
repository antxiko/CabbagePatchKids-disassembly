# The code

## Everything happens inside the interrupt

`INIT` (0x404F) sets the stack at 0xE400, clears 0xE000-0xE3FF, writes
`jp 0x402C` into the H.KEYI hook, sets up the VDP and the PSG, loads the font,
and falls into `jr $` at 0x4080. It never leaves.

From there the interrupt is the program. Every frame it:

1. plays the sound —always, even if the frame before ran long—,
2. reads the controls, if there is a game in play,
3. runs **one step** of the state that `0xE000` names.

`0xE005` is the latch. While a step is running it is set, and if the next
interrupt arrives before the step has finished it only moves the music along
and leaves (`0x404C`). The game slows down; it does not trip over itself.

## The dispatcher, and the table behind the CALL

`DESPACHA` (0x4082) is Konami's: it is called with the index in A and finds its
table by itself.

```
add a,a
pop hl          ; the return address IS the table
call HL_MAS_A
ld e,(hl) / inc hl / ld d,(hl)
ex de,hl
jp (hl)
```

It never returns to the `call`. Five tables use it:

| table | entries | what it picks |
|---|---|---|
| 0x4144 | 20 | the state of the game (`0xE000`) |
| 0x41F8 | 6 | the steps of the menu (`0xE001`) |
| 0x6016 | 17 | the state of the player (`0xE138`) |
| 0x785D | 4 | the action on the kid-picking screen |
| 0x7960 | 4 | the same on the naming screen |

Each one closes exactly against its lowest destination, and that is what gives
its size. They are declared in `src/cabbagepatch.nocode` so the tracer does not
walk into them: read as instructions, they would give false coverage.

## And what runs after the state

Since the dispatcher does not come back, anything that has to run behind the
state has to be left on the stack first. `PASO_DEL_JUEGO` (0x4128) loads HL
with `0x4735` when there is a game in play and with `0x40C1` when there is not,
and pushes it: the state's `ret` lands there.

- `0x4735` blinks the `1P`/`2P` label, one frame in thirty-two.
- `0x40C1` is the menu's: a key takes you to the title with the menu on it
  (state 5), and there the fire key picks the option that the cursor
  (`0xE042`) is on, through the four bytes at `0x4124`.

## The states of the player

Seventeen, in the table at `0x6016`, with six holes that are `0x0000` and are
never used. Walking, in the air, on the swing, on the trampoline, on the log,
the goal, the stage cleared, sinking, hit. The one for being hit
(`LE_HAN_DADO`, 0x6328) turns off four bits of the pattern table —the face
changes— and moves to state 16 with its sound.

Jumps and falls come out of a **table of deltas** read forwards and backwards:
the same list, walked one way subtracting and the other adding, is the rise and
the fall, and the bytes 0xFE and 0xFF are what turn it around and what end it
(`0x5BC4` and friends).

## The sound

The player is Konami's three-channel one, at `0x7AA0`, with **eleven bytes per
channel** from `0xE010`, `0xE01B` and `0xE026`. `SONIDO` (0x7A08) asks for a
number: below 0x0D it is an effect and takes one channel; from 0x0F up it is
music and takes three. The number is also the **priority**: a channel already
playing something with an equal or higher number is not interrupted
(`0x7A2F`).

Notes are a nibble each, with `0xFn` changing octave and `0xDn` setting the
volume, and the twelve periods of one octave live at `0x7BFF`; lower octaves
are that period doubled, once per octave (`add hl,hl`).

## The instruction the Z80 does not have

`DESPLIEGA`, the drawing unpacker, needs `ld (IX+A),B` —a displacement that
changes— and the Z80 only takes a fixed one, inside the opcode. So the
cartridge writes the byte as it goes: seven bytes copied into RAM at `0xE5F8`
that do `ld (0xE5FD),a` and then `ld (ix+00h),b`, where `0xE5FD` is exactly the
operand of that second instruction. It is the only code in the cartridge that
does not run from ROM.
