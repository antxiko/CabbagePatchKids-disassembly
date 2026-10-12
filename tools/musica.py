#!/usr/bin/env python3
"""La musica del cartucho, ejecutando su motor de sonido (ver motor_musica.py).

Pide el sonido con `SONIDO` (0x7A08, A = numero) y corre `EL_REPRODUCTOR`
(0x7AA0), que la interrupcion llama cada cuadro (0x4030). Tres voces de 10
bytes desde 0xE010; la copia del registro 7 del PSG, en 0xE037.
Uso:  musica.py registros 0x8D [cuadros] | mp3 0x8D f.mp3 | todas docs/audio
      musica.py barrido 0x80 0xFF | emu
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import motor_musica  # noqa: E402
from motor_musica import P  # noqa: E402

TABLA = "ninguna llamada directa: está en la tabla de pistas"

PIEZAS = [
    P(0x92, "La música del menú", "The menu tune", "`MENU_2_ARRANCA`"),
    P(0x8D, "El sonido de salida", "The start sound", "`ESTADO_10_ESPERA`"),
    P(0x95, "La fanfarria de meta", "The finish fanfare",
      "`META_ALCANZADA`"),
    P(0x9B, "La muerte", "Death", "`ESTADO_12_MUERTE`"),
    P(0x8F, "La pieza del 0x4283", "The tune at 0x4283", "`L_4283`"),
    P(0x98, "La pieza del 0x4342", "The tune at 0x4342", "`L_4342`"),
    P(0x8E, "Una pista de la tabla", "A track in the table", TABLA),
    P(0x90, "Otra pista de la tabla", "Another track in the table", TABLA),
    P(0x91, "Una tercera pista de la tabla", "A third track in the table",
      TABLA),
    P(0x93, "Una cuarta pista de la tabla", "A fourth track in the table",
      TABLA),
    P(0x94, "Una quinta pista de la tabla", "A fifth track in the table",
      TABLA),
    P(0x96, "Una sexta pista de la tabla", "A sixth track in the table",
      TABLA),
    P(0x97, "Una séptima pista de la tabla", "A seventh track in the table",
      TABLA),
    P(0x99, "Una octava pista de la tabla", "An eighth track in the table",
      TABLA),
    P(0x9A, "Una novena pista de la tabla", "A ninth track in the table",
      TABLA),
]

PAGINA = motor_musica.pagina_basica(
    "`EL_REPRODUCTOR`, 0x7AA0, y `SONIDO`, 0x7A08, que le reparte los "
    "canales; lo llama la interrupción en 0x4030",
    "`EL_REPRODUCTOR`, 0x7AA0, and `SONIDO`, 0x7A08, which hands it the "
    "channels; the interrupt calls it at 0x4030",
    "C-BIOS MSX1 japonés",
    [("la música de salida (0x8D), sus primeros 510 cuadros, hasta que el "
      "juego pide un efecto",
      "the start sound (0x8D), its first 510 frames, up to where the game "
      "asks for an effect"),
     ("la fanfarria de meta (0x95) entera, 194 cuadros",
      "the finish fanfare (0x95), whole, 194 frames")],
    [("Cómo se pide una pieza",
      "`SONIDO` recibe el número en A. Por debajo de 0x8D es un efecto de un "
      "canal; del 0x8D en adelante es música de dos o tres canales. Cada "
      "canal tiene diez bytes desde 0xE010 y 0xE037 guarda la copia del "
      "mezclador del PSG, que el arranque deja en 0xB8. Las pistas «de la "
      "tabla» están en la tabla de pistas pero ninguna rutina las pide con "
      "un `ld a`; se omiten otras de 0x9C en adelante, muy largas y casi "
      "sin notas.",
      "How a piece is asked for",
      "`SONIDO` takes the number in A. Below 0x8D it is a one-channel "
      "effect; from 0x8D up it is two- or three-channel music. Each channel "
      "has ten bytes from 0xE010 and 0xE037 holds the copy of the PSG "
      "mixer, which start-up leaves at 0xB8. The tracks marked «in the "
      "table» are in the track table but no routine asks for them with an "
      "`ld a`; others from 0x9C up, very long and nearly without notes, are "
      "left out.")])

CFG = dict(rom="cabbagepatch.rom", org=0x4000, frame=0x7AA0, pide=0x7A08,
           ram=(0xE010, 0xE034), ram0=[(0xE037, 0xB8)],
           excluye=[0xE019, 0xE024, 0xE02F], hz=60, psg0={7: 0xB8},
           piezas=PIEZAS, pagina=PAGINA,
           cotejado=[(0x8D, 1538, 769), (0x95, 194, None)])

if __name__ == "__main__":
    sys.exit(motor_musica.main(CFG, sys.argv[1:]))
