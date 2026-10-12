# The music

Everything you hear here comes from running the cartridge's own sound engine (`EL_REPRODUCTOR`, 0x7AA0, and `SONIDO`, 0x7A08, which hands it the channels; the interrupt calls it at 0x4030) on an emulated Z80, frame by frame at 60 per second, just as the game calls it. What the engine writes to the PSG is turned into sound with an AY-3-8910 (`tools/musica.py`). Each MP3 is the whole piece up to where it starts again, plus 8 seconds of the repeat fading out; those that do not repeat end where the engine ends.

## Checked against openMSX

The PSG writes have been compared frame by frame with those of openMSX (C-BIOS MSX1 japonés). In every frame the PSG ends up the same:

- the start sound (0x8D), its first 510 frames, up to where the game asks for an effect;
- the finish fanfare (0x95), whole, 194 frames.

The timbre is not checked: it is a textbook AY-3-8910, not a recording of the emulator. The probes are `tools/omsx_psg.tcl` and `tools/coteja_psg.py`.

## How a piece is asked for

`SONIDO` takes the number in A. Below 0x8D it is a one-channel effect; from 0x8D up it is two- or three-channel music. Each channel has ten bytes from 0xE010 and 0xE037 holds the copy of the PSG mixer, which start-up leaves at 0xB8. The tracks marked «in the table» are in the track table but no routine asks for them with an `ld a`; others from 0x9C up, very long and nearly without notes, are left out.

## The tunes

**The menu tune** (0x92)

Asked for by `MENU_2_ARRANCA`; lasts 12.8 s and starts again at second 6.4.

<audio controls preload="none" src="audio/musica_92.mp3?v=6d6b1107"></audio>

**The start sound** (0x8D)

Asked for by `ESTADO_10_ESPERA`; lasts 25.6 s and starts again at second 12.8.

<audio controls preload="none" src="audio/musica_8D.mp3?v=b18051fe"></audio>

**The finish fanfare** (0x95)

Asked for by `META_ALCANZADA`; lasts 3.2 s.

<audio controls preload="none" src="audio/musica_95.mp3?v=889feaab"></audio>

**Death** (0x9B)

Asked for by `ESTADO_12_MUERTE`; lasts 5.2 s.

<audio controls preload="none" src="audio/musica_9B.mp3?v=e094d615"></audio>

**The tune at 0x4283** (0x8F)

Asked for by `L_4283`; lasts 6.4 s.

<audio controls preload="none" src="audio/musica_8F.mp3?v=5dcfd562"></audio>

**The tune at 0x4342** (0x98)

Asked for by `L_4342`; lasts 2.4 s.

<audio controls preload="none" src="audio/musica_98.mp3?v=b18e239e"></audio>

**A track in the table** (0x8E)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 12.8 s.

<audio controls preload="none" src="audio/musica_8E.mp3?v=6e3c40b9"></audio>

**Another track in the table** (0x90)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 6.4 s and starts again at second 0.0.

<audio controls preload="none" src="audio/musica_90.mp3?v=5153035b"></audio>

**A third track in the table** (0x91)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 12.8 s and starts again at second 6.4.

<audio controls preload="none" src="audio/musica_91.mp3?v=06829b91"></audio>

**A fourth track in the table** (0x93)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 6.8 s.

<audio controls preload="none" src="audio/musica_93.mp3?v=a3df1d3a"></audio>

**A fifth track in the table** (0x94)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 6.8 s.

<audio controls preload="none" src="audio/musica_94.mp3?v=cd27d815"></audio>

**A sixth track in the table** (0x96)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 3.2 s.

<audio controls preload="none" src="audio/musica_96.mp3?v=3ef5389c"></audio>

**A seventh track in the table** (0x97)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 3.2 s.

<audio controls preload="none" src="audio/musica_97.mp3?v=a0271f56"></audio>

**An eighth track in the table** (0x99)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 5.2 s.

<audio controls preload="none" src="audio/musica_99.mp3?v=7930d615"></audio>

**A ninth track in the table** (0x9A)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 5.2 s.

<audio controls preload="none" src="audio/musica_9A.mp3?v=a93504fa"></audio>
