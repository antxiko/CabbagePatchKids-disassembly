# El código

## Todo pasa dentro de la interrupción

`INIT` (0x404F) pone la pila en 0xE400, borra 0xE000-0xE3FF, escribe
`jp 0x402C` en el gancho H.KEYI, prepara el VDP y el PSG, carga la fuente y cae
en un `jr $` en 0x4080. De ahí no sale nunca.

A partir de ese momento la interrupción es el programa. Cada fotograma:

1. toca el sonido —siempre, aunque el fotograma anterior se haya alargado—,
2. lee los mandos, si hay partida en marcha,
3. ejecuta **un paso** del estado que diga `0xE000`.

`0xE005` es el candado. Mientras un paso está corriendo está puesto, y si la
interrupción siguiente llega antes de que acabe, sólo mueve la música y se va
(`0x404C`). El juego se ralentiza; no se atropella.

## El despachador, y la tabla detrás del CALL

`DESPACHA` (0x4082) es el de Konami: se le llama con el índice en A y la tabla
se la encuentra él solo.

```
add a,a
pop hl          ; la direccion de retorno ES la tabla
call HL_MAS_A
ld e,(hl) / inc hl / ld d,(hl)
ex de,hl
jp (hl)
```

Nunca vuelve al `call`. Lo usan cinco tablas:

| tabla | entradas | qué elige |
|---|---|---|
| 0x4144 | 20 | el estado del juego (`0xE000`) |
| 0x41F8 | 6 | los pasos del menú (`0xE001`) |
| 0x6016 | 17 | el estado del jugador (`0xE138`) |
| 0x785D | 4 | la acción en la pantalla de elegir muñeco |
| 0x7960 | 4 | la misma en la del nombre |

Cada una cierra clavada contra su destino más bajo, y eso es lo que da su
tamaño. Van declaradas en `src/cabbagepatch.nocode` para que el trazador no se
meta dentro: leídas como instrucciones darían cobertura falsa.

## Y lo que corre DESPUÉS del estado

Como el despachador no vuelve, lo que tenga que correr detrás hay que dejarlo
en la pila antes. `PASO_DEL_JUEGO` (0x4128) carga HL con `0x4735` si hay
partida y con `0x40C1` si no, y hace `push hl`: el `ret` del estado aterriza
ahí.

- `0x4735` hace parpadear el rótulo `1P`/`2P`, uno de cada 32 fotogramas.
- `0x40C1` es el del menú: una tecla lleva al título con el menú puesto (estado
  5), y allí el disparo elige la opción sobre la que esté el cursor
  (`0xE042`), por los cuatro bytes de `0x4124`.

## Los estados del jugador

Diecisiete, en la tabla de `0x6016`, con seis huecos que son `0x0000` y no se
usan. Andando, en el aire, en el columpio, en el trampolín, sobre el tronco, la
meta, la fase superada, hundiéndose, le han dado. El de que le den
(`LE_HAN_DADO`, 0x6328) apaga cuatro bits de la tabla de patrones —la cara
cambia— y pasa al estado 16 con su sonido.

Los saltos y las caídas salen de una **tabla de incrementos leída de ida y de
vuelta**: la misma lista, recorrida en un sentido restando y en el otro
sumando, es la subida y la bajada, y los bytes 0xFE y 0xFF son lo que la hace
dar la vuelta y lo que la acaba (`0x5BC4` y compañía).

## El sonido

El reproductor es el de tres canales de la casa, en `0x7AA0`, con **once bytes
por canal** desde `0xE010`, `0xE01B` y `0xE026`. `SONIDO` (0x7A08) pide un
número: por debajo de 0x0D es un efecto y ocupa un canal; de 0x0F en adelante
es música y ocupa tres. El número es además la **prioridad**: a un canal que ya
esté sonando algo de número igual o mayor no se le pisa (`0x7A2F`).

Las notas son un nibble cada una, con `0xFn` para cambiar de octava y `0xDn`
para fijar el volumen, y los doce periodos de una octava están en `0x7BFF`; las
octavas de abajo son ese periodo doblado, una vez por octava (`add hl,hl`).

## La instrucción que el Z80 no tiene

`DESPLIEGA`, el desplegador de dibujos, necesita `ld (IX+A),B` —un
desplazamiento que cambia— y el Z80 sólo admite el fijo, dentro del opcode. Así
que el cartucho escribe ese byte en marcha: siete bytes copiados a la RAM en
`0xE5F8` que hacen `ld (0xE5FD),a` y luego `ld (ix+00h),b`, donde `0xE5FD` es
justo el operando de esa segunda instrucción. Es el único código del cartucho
que no corre desde la ROM.

## Código compartido con otros cartuchos de Konami

Este desensamblado se ha comparado, instrucción por instrucción, con
todos los demás de Konami de la serie. Cuenta un bloque cuando las
mismas instrucciones, al menos seis desde una etiqueta hasta su `ret`
o su salto sin condición, están en los dos cartuchos; las direcciones
no se miran, porque cambian de un cartucho a otro. De los otros 57,
**47** tienen al menos un bloque en común con este; estos son los
que más comparten:

| Cartucho | Bloques | Instrucciones | Por ejemplo (aquí = allí) |
|---|---:|---:|---|
| [Athletic Land](https://antxiko.github.io/AthleticLand-disassembly/es/) | 72 | 1.114 | `COBRA_PUNTOS` (0x5FA3) |
| [Magical Tree](https://antxiko.github.io/MagicalTree-disassembly/es/) | 25 | 298 | `LEE_EL_TECLADO` (0x409C) = `lee_el_teclado` |
| [Circus Charlie](https://antxiko.github.io/CircusCharlie-disassembly/es/) | 23 | 255 | `LEE_EL_TECLADO` (0x409C) = `lee_el_teclado` |
| [Comic Bakery](https://antxiko.github.io/ComicBakery-disassembly/es/) | 20 | 206 | `LEE_EL_TECLADO` (0x409C) = `lee_el_teclado` |
| [Konami’s Mahjong Dojo](https://antxiko.github.io/KonamisMahjongDojo-disassembly/es/) | 18 | 214 | `RELLENA_VRAM` (0x4522) = `rellena_la_vram` |
| [Hyper Sports 1](https://antxiko.github.io/HyperSports1-disassembly/es/) | 17 | 210 | `LEE_EL_TECLADO` (0x409C) = `LEE_TECLADO` |
| [Yie Ar Kung-Fu](https://antxiko.github.io/YieArKungFu-disassembly/es/) | 12 | 155 | `LEE_EL_TECLADO` (0x409C) = `lee_el_teclado` |
| [Monkey Academy](https://antxiko.github.io/MonkeyAcademy-disassembly/es/) | 10 | 115 | `PINTA_BCD` (0x4718) = `PINTA_BYTES_BCD` |
| [Super Cobra](https://antxiko.github.io/SuperCobra-disassembly/es/) | 10 | 97 | `SONIDO_SIGUIENTE_VUELTA` (0x7A5D) = `SONIDO_ENCADENADO` |
| [Konami’s Billiards](https://antxiko.github.io/KonamisBilliards-disassembly/es/) | 8 | 97 | `PINTA_FASE` (0x4710) = `pinta_el_numero_de_fase` |

La matriz entera, los 58 cartuchos entre sí, está en
[Las rutinas](https://antxiko.github.io/MSX-disassembly-database/es/LAS-RUTINAS.html) de la base de datos de la
serie, con el método y el programa que la mide.
