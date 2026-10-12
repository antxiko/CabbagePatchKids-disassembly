# La música

Todo lo que suena aquí sale de ejecutar el motor de sonido del cartucho (`EL_REPRODUCTOR`, 0x7AA0, y `SONIDO`, 0x7A08, que le reparte los canales; lo llama la interrupción en 0x4030) en un Z80 emulado, cuadro a cuadro y a 60 por segundo, igual que lo llama el juego. Lo que el motor escribe en el PSG pasa a sonido con un AY-3-8910 (`tools/musica.py`). Cada MP3 es la pieza entera hasta donde vuelve a empezar, más 8 segundos de la vuelta apagándose; las que no se repiten acaban donde acaba el motor.

## Cotejado con openMSX

Las escrituras al PSG se han comparado cuadro a cuadro con las de openMSX (C-BIOS MSX1 japonés). En todos los cuadros el PSG queda igual:

- la música de salida (0x8D), sus primeros 510 cuadros, hasta que el juego pide un efecto;
- la fanfarria de meta (0x95) entera, 194 cuadros.

El timbre no está cotejado: es el de un AY-3-8910 de manual, no una grabación del emulador. Las sondas están en `tools/omsx_psg.tcl` y `tools/coteja_psg.py`.

## Cómo se pide una pieza

`SONIDO` recibe el número en A. Por debajo de 0x8D es un efecto de un canal; del 0x8D en adelante es música de dos o tres canales. Cada canal tiene diez bytes desde 0xE010 y 0xE037 guarda la copia del mezclador del PSG, que el arranque deja en 0xB8. Las pistas «de la tabla» están en la tabla de pistas pero ninguna rutina las pide con un `ld a`; se omiten otras de 0x9C en adelante, muy largas y casi sin notas.

## Las músicas

**La música del menú** (0x92)

Lo pide `MENU_2_ARRANCA`; dura 12,8 s y vuelve a empezar en el segundo 6,4.

<audio controls preload="none" src="../audio/musica_92.mp3?v=6d6b1107"></audio>

**El sonido de salida** (0x8D)

Lo pide `ESTADO_10_ESPERA`; dura 25,6 s y vuelve a empezar en el segundo 12,8.

<audio controls preload="none" src="../audio/musica_8D.mp3?v=b18051fe"></audio>

**La fanfarria de meta** (0x95)

Lo pide `META_ALCANZADA`; dura 3,2 s.

<audio controls preload="none" src="../audio/musica_95.mp3?v=889feaab"></audio>

**La muerte** (0x9B)

Lo pide `ESTADO_12_MUERTE`; dura 5,2 s.

<audio controls preload="none" src="../audio/musica_9B.mp3?v=e094d615"></audio>

**La pieza del 0x4283** (0x8F)

Lo pide `L_4283`; dura 6,4 s.

<audio controls preload="none" src="../audio/musica_8F.mp3?v=5dcfd562"></audio>

**La pieza del 0x4342** (0x98)

Lo pide `L_4342`; dura 2,4 s.

<audio controls preload="none" src="../audio/musica_98.mp3?v=b18e239e"></audio>

**Una pista de la tabla** (0x8E)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 12,8 s.

<audio controls preload="none" src="../audio/musica_8E.mp3?v=6e3c40b9"></audio>

**Otra pista de la tabla** (0x90)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 6,4 s y vuelve a empezar en el segundo 0,0.

<audio controls preload="none" src="../audio/musica_90.mp3?v=5153035b"></audio>

**Una tercera pista de la tabla** (0x91)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 12,8 s y vuelve a empezar en el segundo 6,4.

<audio controls preload="none" src="../audio/musica_91.mp3?v=06829b91"></audio>

**Una cuarta pista de la tabla** (0x93)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 6,8 s.

<audio controls preload="none" src="../audio/musica_93.mp3?v=a3df1d3a"></audio>

**Una quinta pista de la tabla** (0x94)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 6,8 s.

<audio controls preload="none" src="../audio/musica_94.mp3?v=cd27d815"></audio>

**Una sexta pista de la tabla** (0x96)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 3,2 s.

<audio controls preload="none" src="../audio/musica_96.mp3?v=3ef5389c"></audio>

**Una séptima pista de la tabla** (0x97)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 3,2 s.

<audio controls preload="none" src="../audio/musica_97.mp3?v=a0271f56"></audio>

**Una octava pista de la tabla** (0x99)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 5,2 s.

<audio controls preload="none" src="../audio/musica_99.mp3?v=7930d615"></audio>

**Una novena pista de la tabla** (0x9A)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 5,2 s.

<audio controls preload="none" src="../audio/musica_9A.mp3?v=a93504fa"></audio>
