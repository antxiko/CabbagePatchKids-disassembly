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
