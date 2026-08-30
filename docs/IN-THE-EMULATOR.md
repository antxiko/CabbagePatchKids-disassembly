# In the emulator

The pictures in the gallery are drawn from the ROM, without an emulator. This
page is the other thing: what was checked by **running the cartridge**, which
is the only way to know that a screen exists and looks the way the code says it
should.

The harness is `tools/omsx_capturas.tcl`, on a Philips VG-8020 —a real MSX1 of
the period— with the cartridge given on the command line:

```
CPK_OUT=work/shots CPK_TECLAS="16 BARRA;19 ABAJO;23 FOTO" \
  openmsx -machine Philips_VG_8020 -cart cabbagepatch.rom \
          -script tools/omsx_capturas.tcl
```

`CPK_TECLAS` is a list of `second key` pairs, and `FOTO` takes a screenshot.
Keys are pressed on the **key matrix**, not typed: `type` would write the word.

## What it settled

- **The two set-up screens are what the code says they are.** The first shows
  the kid inside a green frame with the four keys listed underneath —
  `FORWARD`, `BACKWARD`, `CURSOR`, `END`—, which are exactly the four actions
  `0x79BA` turns a keypress into. The second adds `--NAME--` and the name.
- **The factory name really is ANNA LEE**, and it is on screen before you touch
  anything.
- **The park is called BABYLAND PARK**, and the babies grow in cabbages. The
  sign is the seventeen tiles at `0x6BE5`.
- **The title screen credits `© OAA,INC. 1983`**, which is not the same as the
  `©KONAMI 1984` of the play screen.

## Two traps that cost a capture each

- Launched with `-script`, openMSX starts with the renderer *uninitialized* and
  `screenshot` returns a black PNG with rc=0. It has to be turned on by hand
  with `set renderer SDLGL-PP`.
- With `set throttle off` the machine runs flat out and the renderer skips
  frames, so the capture has to be asked for with the throttle **on** and with
  `after realtime`, which is wall-clock time.

## And one thing the emulator would not give

Getting to the naming screen by pressing keys does not work if the option
chosen on the menu is a joystick one, because then the game reads the joystick
and the keyboard is ignored. Rather than fight it, the menu step is pushed on
by hand —`CPK_POKE="30 0xE001 4"` writes that byte at that second—, which is
the same thing the game does when it moves along, only without waiting for the
right key.
